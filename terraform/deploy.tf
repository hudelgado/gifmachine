
locals {
  name = "gifmachine"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  container_name            = "${local.name}-rails"
  container_port            = 4567
  db_migrate_container_name = "${local.name}-db-migrate"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source     = "terraform-aws-modules/vpc/aws"
  version    = "~> 5.0"
  create_vpc = true

  name = local.name
  cidr = var.vpc_cidr

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  azs              = local.azs
  private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 1)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 6)]

  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "db" {
  source = "terraform-aws-modules/rds-aurora/aws"
  create = true

  name              = "${local.name}-postgresqlv2"
  engine            = "aurora-postgresql"
  engine_mode       = "provisioned"
  engine_version    = "14.5"
  storage_type      = "aurora"
  storage_encrypted = true

  master_username = var.database_username
  master_password = var.database_password
  database_name   = var.database_name

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
    outbound_access = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  serverlessv2_scaling_configuration = {
    min_capacity = 1
    max_capacity = 1
  }

  instance_class = var.instance_class
}


################################################################################
# ECS Cluster
################################################################################

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = local.name

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

}

################################################################################
# Web Service
################################################################################

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = local.name
  cluster_arn = module.ecs_cluster.arn

  cpu    = 256
  memory = 512

  enable_execute_command = false
  container_definition_defaults = {
    environment = [{
      name  = "DATABASE_URL"
      value = "postgres://${var.database_username}:${var.database_username}@${module.db.cluster_endpoint}"
      }, {
      name  = "RAILS_ENV"
      value = "production"
      }
    ]
  }

  # Container definition(s)
  container_definitions = {

    (local.container_name) = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "${module.code_deploy.0.repository_url}:latest"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      readonly_root_filesystem  = false
      enable_cloudwatch_logging = true

      linux_parameters = {
        capabilities = {
          drop = [
            "NET_RAW"
          ]
        }
      }

      memory_reservation = 100
    }
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.this.arn
    service = {
      client_alias = {
        port     = local.container_port
        dns_name = local.container_name
      }
      port_name      = local.container_name
      discovery_name = local.container_name
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ex_ecs"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

}

################################################################################
# DB-Migration task
################################################################################
resource "aws_cloudwatch_log_group" "gifmachine_db_migrate" {
  name = "gifmachine_db_migrate"
}
data "template_file" "db_migrate_task" {
  template = file("task-definitions/db_migrate.json")

  vars = {
    image        = "${module.code_deploy.0.repository_url}:latest"
    database_url = "postgres://${var.database_username}:${var.database_username}@${module.db.cluster_endpoint}"
  }
}

resource "aws_ecs_task_definition" "db_migrate" {
  family                   = "${local.name}_db_migrate"
  container_definitions    = data.template_file.db_migrate_task.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = module.ecs_service.task_exec_iam_role_arn
  task_role_arn            = module.ecs_service.tasks_iam_role_arn
}



################################################################################
# Supporting Resources
################################################################################

resource "aws_service_discovery_http_namespace" "this" {
  name        = local.name
  description = "CloudMap namespace for ${local.name}"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_ecs"
      }
    }
  }

  target_groups = {
    ex_ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = local.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
  }

}


module "code_deploy" {
  source = "./modules/code_deploy"
  count  = 1

  region                 = var.region
  ecr_repository_name    = local.name
  source_code_repository = var.repository_name
  ecs_cluster_name       = module.ecs_cluster.name
  ecs_service_name       = module.ecs_service.name
  database_endpoint      = module.db.cluster_endpoint
  subnet_id              = module.vpc.private_subnets[0]
  security_group_ids = [
    module.vpc.default_security_group_id
  ]
}

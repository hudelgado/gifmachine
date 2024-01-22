variable "region" {
  type = string
}

variable "ecr_repository_name" {
  type = string
}

variable "source_code_repository" {
  type = string
}

variable "database_endpoint" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}
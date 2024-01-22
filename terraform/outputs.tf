output "alb_dns_name" {
  value = try(module.alb.dns_name, null)
}

output "rds_endpoint" {
  value = try(module.db.cluster_endpoint, null)
}

output "rds_cluster_arn" {
  value = try(module.db.0.cluster_arn, null)
}
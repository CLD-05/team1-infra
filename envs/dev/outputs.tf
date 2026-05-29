# outputs.tf

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "alb_controller_role_arn" {
  value = module.eks.alb_controller_role_arn
}

output "eso_role_arn" {
  value = module.eks.eso_role_arn
}

output "ecr_repository_urls" {
  value = module.ecr.repository_uris
}

output "rds_primary_endpoint" {
  value = module.rds.primary_endpoint
}

output "rds_replica_endpoint" {
  value = module.rds.replica_endpoint
}

# output "redis_endpoint" {
#   value = module.elasticache.redis_endpoint
# }

output "github_actions_role_arn" {
  value = module.github_oidc.role_arn
}

output "bastion_instance_id" {
  value = module.bastion.instance_id
}

# modules/eks/outputs.tf
#
# 출력값:
#   - cluster_name            : EKS 클러스터 이름
#   - cluster_endpoint        : API 서버 엔드포인트 (sensitive)
#   - cluster_version         : K8s 버전
#   - oidc_provider_arn       : IRSA 구성 시 사용
#   - node_security_group_id  : 노드 SG ID
#   - alb_controller_role_arn : ALB Controller IRSA Role ARN

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "cluster_version" {
  value = module.eks.cluster_version
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "alb_controller_role_arn" {
  value       = module.alb_controller_irsa.iam_role_arn
  description = "ALB Controller IRSA Role ARN"
}

output "ebs_csi_role_arn" {
  value       = module.ebs_csi_irsa.iam_role_arn
  description = "EBS CSI Driver IRSA Role ARN"
}

output "eso_role_arn" {
  value       = module.eso_irsa.iam_role_arn
  description = "ESO IRSA Role ARN"
}

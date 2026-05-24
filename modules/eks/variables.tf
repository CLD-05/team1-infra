# modules/eks/variables.tf
#
# 주요 변수:
#   - bastion_security_group_id: Bastion SG ID
#     -> EKS API 서버 보안그룹에 Bastion SG 443 인바운드 허용 규칙 추가

variable "cluster_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "bastion_security_group_id" {
  type        = string
  description = "Bastion SG ID — API 서버 443 접근 허용"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_min" {
  type    = number
  default = 2
}

variable "node_max" {
  type    = number
  default = 10
}

variable "node_desired" {
  type    = number
  default = 2
}

variable "bastion_role_arn" {
  description = "Bastion EC2 IAM Role ARN (EKS AccessEntry)"
  type        = string
}

# modules/rds/variables.tf

variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "isolated_subnet_ids" {
  type        = list(string)
  description = "RDS 배치할 Isolated 서브넷 ID 목록"
}

variable "node_security_group_id" {
  type        = string
  description = "EKS 노드 SG ID (RDS 접근 허용)"
}

variable "bastion_security_group_id" {
  type        = string
  description = "Bastion SG ID (RDS 접근 허용)"
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_name" {
  type    = string
  default = "enrollment"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "multi_az" {
  type        = bool
  default     = false
  description = "Day 1~5: false / Day 6 시연 전: true로 변경"
}

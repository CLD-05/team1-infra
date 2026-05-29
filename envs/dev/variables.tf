# variables.tf

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project" {
  type        = string
  default     = "team1"
  description = "리소스 이름 prefix"
}

variable "cluster_name" {
  type        = string
  default     = "team1-cluster"
  description = "EKS 클러스터 이름"
}

variable "environment" {
  type        = string
  default     = "team1-dev"
  description = "환경 이름"
}

# VPC
variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.1.4.0/22", "10.1.8.0/22"]
}

variable "isolated_cidrs" {
  type    = list(string)
  default = ["10.1.20.0/24", "10.1.21.0/24"]
}

# EKS
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

# RDS
# variable "db_username" {
#   type      = string
#   sensitive = true
# }

# variable "db_password" {
#   type      = string
#   sensitive = true
# }

variable "multi_az" {
  type    = bool
  default = false
}

# GitHub OIDC
variable "github_org" {
  type        = string
  description = "GitHub 조직명 또는 사용자명"
}

variable "github_repo" {
  type        = string
  description = "GitHub 레포지토리명"
}

# ECR
variable "repositories" {
  type    = list(string)
  default = ["team1-course-service", "team1-enroll-service"]
}

variable "use_ssm" {
  type    = bool
  default = true
}

variable "key_name" {
  type    = string
  default = ""
}

variable "my_ip" {
  type    = string
  default = ""
}

variable "enable_nat_per_az" {
  type    = bool
  default = false
}

# CloudFront
variable "aws_account_id" {
  type        = string
  description = "AWS 계정 ID"
}

# variable "domain_name" {
#   type        = string
#   description = "서비스 도메인 이름"
# }

# variable "route53_zone_id" {
#   type        = string
#   description = "Route53 호스팅 영역 ID"
# }

# variable "alb_dns_name" {
#   type        = string
#   description = "EKS에 배포된 ALB의 DNS 주소"
# }

# modules/vpc/variables.tf
#
# 역할: VPC 모듈 입력 변수 정의
#   - project      : 리소스 이름 prefix (예: tf)
#   - vpc_cidr     : VPC CIDR 블록
#   - azs          : 가용 영역 목록
#   - public_cidrs : 퍼블릭 서브넷 CIDR 목록
#   - private_cidrs: 프라이빗 서브넷 CIDR 목록
#   - cluster_name : EKS 클러스터 이름 (태그용)

variable "project" {
  type        = string
  description = "team1-tf"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "cluster_name" {
  type        = string
  description = "team1-cluster"
}

variable "isolated_cidrs" {
  type    = list(string)
  default = ["10.0.5.0/24", "10.0.6.0/24"]
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

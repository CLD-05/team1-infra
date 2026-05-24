# modules/bastion/variables.tf

variable "project" {
  description = "리소스 이름 prefix"
  type        = string
}

variable "vpc_id" {
  description = "Bastion을 배치할 VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Bastion 배치할 퍼블릭 서브넷 ID"
  type        = string
}

variable "instance_type" {
  description = "Bastion EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "use_ssm" {
  type        = bool
  default     = false
  description = "true: SSM 방식 (팀 계정) / false: 키 페어 방식 (로컬)"
}

variable "key_name" {
  type        = string
  default     = ""
  description = "키 페어 방식일 때 사용 (use_ssm = false)"
}

variable "my_ip" {
  type        = string
  default     = ""
  description = "SSH 허용 IP (use_ssm = false)"
}

# modules/ecr/variables.tf

variable "project" {
  description = "리소스 이름 prefix (태그용)"
  type        = string
}

variable "repositories" {
  description = "생성할 ECR Repository 이름 목록"
  type        = list(string)
}

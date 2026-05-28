# modules/github-oidc/variables.tf

variable "github_org" {
  description = "GitHub 사용자명 또는 조직명"
  type        = string
}

variable "github_repo" {
  description = "GitHub 저장소명"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

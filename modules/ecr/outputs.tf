# modules/ecr/outputs.tf
#
# 출력값:
#   - repository_uris : {repository_name => URI} 맵
#     예: {"ops-app1" = "111111111111.dkr.ecr.ap-northeast-2.amazonaws.com/ops-app1"}
#   - repository_arns : {repository_name => ARN} 맵

output "repository_uris" {
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.repository_url
  }
  description = "ECR Repository URI 맵"
}

output "repository_arns" {
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.arn
  }
  description = "ECR Repository ARN 맵"
}

output "repository_names" {
  value       = [for repo in aws_ecr_repository.this : repo.name]
  description = "생성된 Repository 이름 목록"
}

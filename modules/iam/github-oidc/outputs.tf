# modules/github-oidc/outputs.tf

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "GitHub OIDC Provider ARN"
}

output "role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "GitHub Actions가 Assume할 Role ARN"
}

output "role_name" {
  value       = aws_iam_role.github_actions.name
  description = "GitHub Actions Role 이름"
}

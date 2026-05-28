# modules/github-oidc/main.tf
#
# 생성 리소스:
#   - aws_iam_openid_connect_provider : GitHub OIDC Provider
#   - aws_iam_role: github-actions-terraform-role
#     -> 지정한 저장소의 GitHub Actions만 Assume 가능
#   - aws_iam_role_policy_attachment : AdministratorAccess (실습용)
#
# 본 Role을 GitHub Actions Workflow에서 사용:
#   - uses: aws-actions/configure-aws-credentials@v4
#     with:
#       role-to-assume: <github_oidc_role_arn>
#       aws-region: ap-northeast-2

# GitHub OIDC Provider
# thumbprints는 GitHub 공식 인증서 SHA-1 해시
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name = "team1-github-actions-oidc"
  }
}

# GitHub Actions용 IAM Role
# Trust Policy: 지정한 저장소의 GitHub Actions만 Assume 가능
resource "aws_iam_role" "github_actions" {
  name = "${var.project}-github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })

  tags = {
    Name = "team1-github-actions-terraform-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecr_power_user" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

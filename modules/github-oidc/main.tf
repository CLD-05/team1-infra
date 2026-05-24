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
    Name = "github-actions-oidc"
  }
}

# GitHub Actions용 IAM Role
# Trust Policy: 지정한 저장소의 GitHub Actions만 Assume 가능
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-role"

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
    Name = "github-actions-terraform-role"
  }
}

# 실무에서는 최소 권한 적용:
#   - ECR Push·Pull: AmazonEC2ContainerRegistryPowerUser
#   - S3 GetObject: 특정 버킷만 명시
# ECR Push용 권한만
resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-policy"
  role = aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

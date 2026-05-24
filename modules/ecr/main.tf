# modules/ecr/main.tf
#
# 생성 리소스:
#   - aws_ecr_repository × N
#     - image_tag_mutability: IMMUTABLE (같은 태그 덮어쓰기 차단)
#     - scan_on_push: true (취약점 자동 스캔)
#     - encryption_configuration: AES256
#   - aws_ecr_lifecycle_policy × N
#     - 최근 30개 이미지 보존, 이후 자동 만료

resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = each.value
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "최근 30개 이미지 보존, 이후 자동 만료"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# modules/irsa-test/main.tf
#
# 생성 리소스:
#   - aws_s3_bucket                  : IRSA 검증용 테스트 S3 버킷
#   - aws_s3_object                  : 버킷에 업로드할 테스트 파일 (hello.txt)
#   - aws_iam_role (s3_reader)       : S3 읽기 전용 IRSA Role
#     -> 신뢰 정책: default/s3-reader-sa ServiceAccount만 Assume 허용
#   - aws_iam_role_policy_attachment : AmazonS3ReadOnlyAccess 연결
#
# 검증 목적:
#   - IRSA 있는 Pod: aws s3 ls 성공
#   - IRSA 없는 Pod: aws s3 ls 실패 (AccessDenied)

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "irsa_test" {
  bucket        = "${var.project}-irsa-test-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags = {
    Name = "${var.project}-irsa-test"
  }
}

resource "aws_s3_object" "test_file" {
  bucket  = aws_s3_bucket.irsa_test.bucket
  key     = "hello.txt"
  content = "IRSA 정상 동작 확인!"
}

resource "aws_iam_role" "s3_reader" {
  name = "${var.project}-s3-reader-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:default:s3-reader-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.s3_reader.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

variable "project" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

output "s3_bucket_name" {
  value = aws_s3_bucket.irsa_test.bucket
}

output "s3_reader_role_arn" {
  value = aws_iam_role.s3_reader.arn
}

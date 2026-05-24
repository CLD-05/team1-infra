# bootstrap/main.tf
#
# 생성 리소스:
#   - aws_s3_bucket                  : Terraform state 저장소
#   - aws_s3_bucket_versioning       : state 백업용 버저닝
#   - aws_s3_bucket_server_side_encryption_configuration : 암호화
#   - aws_s3_bucket_public_access_block : 퍼블릭 액세스 차단
#   - aws_dynamodb_table             : state lock용 테이블

resource "aws_s3_bucket" "terraform_state" {
  bucket = "team1-terraform-state"

  tags = {
    Name      = "team1-terraform-state"
    ManagedBy = "terraform"
  }
}

# 버저닝 활성화 (state 백업)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# DynamoDB state lock 테이블
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "terraform-lock"
    ManagedBy = "terraform"
  }
}

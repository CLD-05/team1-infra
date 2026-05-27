# backend.tf

terraform {
  backend "s3" {
    bucket         = "tfstate-lionkdt5-team1"
    key            = "project2/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "tfstate-lock-team1"
    encrypt        = true
  }
}

# backend.tf

terraform {
  backend "s3" {
    bucket         = "team1-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

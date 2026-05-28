# modules/cloudfront/variables.tf

variable "env"             { description = "환경명 (dev/prod)" }
variable "aws_account_id" { description = "AWS 계정 ID (S3 버킷명 유일성)" }
variable "domain_name"    { description = "커스텀 도메인 (예: team1.example.com)" }
variable "route53_zone_id" { description = "Route53 Hosted Zone ID" }
variable "alb_dns_name"   { description = "ALB DNS명 (k8s Ingress 생성 후 입력)" }

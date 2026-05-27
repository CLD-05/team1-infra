# modules/cloudfront/main.tf

# 생성 리소스:
# - S3 버킷 (정적 리소스)
# - ACM 인증서 (us-east-1 고정 — CloudFront 필수 요건)
# - WAF WebACL (us-east-1 고정)
# - CloudFront Distribution
#   Origin1: ALB (동적 — Spring Boot)
#   Origin2: S3  (정적 리소스)


# ACM 인증서 (us-east-1 고정)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "main" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"        # Route53을 통한 자동 DNS 레코드 검증 방식 채택

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.env}-acm" }
}

# DNS 검증 레코드 (Route53에 자동 생성)
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}


# ACM 인증서 검증 완료 승인 레이어
resource "aws_acm_certificate_validation" "main" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}


# WAF WebACL (us-east-1 고정)
# 대규모 수강신청 트래픽의 1차 웹 방화벽
# CloudFront에 연결하는 WAF는 반드시 us-east-1에 생성
resource "aws_wafv2_web_acl" "main" {
  provider    = aws.us_east_1
  name        = "${var.env}-waf"
  description = "WAF for CloudFront"
  scope       = "CLOUDFRONT"                # ALB용은 REGIONAL, CloudFront용은 CLOUDFRONT

  default_action {
    allow {}                                # 기본 허용, 아래 rule이 차단
  }

  # AWS 관리형 규칙 — 일반적인 웹 공격 차단
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action { none {} }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # 속도 기반 규칙 — IP당 5분에 2000 요청 초과 시 차단 (DDoS 방어)
  rule {
    name     = "RateLimitRule"
    priority = 2

    action { block {} }

    statement {
      rate_based_statement {
        limit              = var.env == "dev" ? 5000 : 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env}-waf"
    sampled_requests_enabled   = true
  }

  tags = { Name = "${var.env}-waf" }
}


# S3 버킷 (정적 리소스)
resource "aws_s3_bucket" "static" {
  bucket        = "${var.env}-team1-static-${var.aws_account_id}"
  force_destroy = true                      # terraform destroy 시 버킷 내용도 삭제

  tags = { Name = "${var.env}-static-bucket" }
}

# 퍼블릭 액세스 차단 (CloudFront OAC로만 접근)
resource "aws_s3_bucket_public_access_block" "static" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront OAC (Origin Access Control) — S3 직접 접근 차단
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.env}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 버킷 정책 — CloudFront OAC만 접근 허용
resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontAccess"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.static.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
        }
      }
    }]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = "${var.env}-distribution"
  default_root_object = "index.html"
  aliases             = [var.domain_name]  # 커스텀 도메인 연결
  web_acl_id          = aws_wafv2_web_acl.main.arn

  # ALB (동적 콘텐츠 — Spring Boot)
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"   # ALB → CloudFront 구간 HTTPS
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # S3 (정적 리소스)
  origin {
    domain_name              = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # 기본 동작 — ALB로 전달 (동적 콘텐츠)
  default_cache_behavior {
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"  # HTTP → HTTPS 리다이렉트
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true                         # 쿼리 파라미터 ALB에 전달
      cookies { forward = "all" }                 # 쿠키 전달 (JWT 쿠키 필수)
      headers = ["Authorization", "Host"]
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # /static/* 경로 — S3로 전달 (정적 리소스)
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 86400                           # 정적 리소스 1일 캐시
    max_ttl     = 31536000                        # 최대 1년
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = { Name = "${var.env}-cloudfront" }
}

# Route53 레코드 (CloudFront 연결)
resource "aws_route53_record" "main" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

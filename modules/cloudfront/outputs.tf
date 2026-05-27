# modules/cloudfront/outputs.tf

output "cloudfront_domain"      {
  value = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_id"          {
  value = aws_cloudfront_distribution.main.id
}

output "cloudfront_arn"         {
  value = aws_cloudfront_distribution.main.arn
}

output "s3_bucket_name"         {
  value = aws_s3_bucket.static.bucket
}

output "acm_certificate_arn"    {
  value = aws_acm_certificate_validation.main.certificate_arn
}

output "waf_arn" {
  value = aws_wafv2_web_acl.main.arn
}

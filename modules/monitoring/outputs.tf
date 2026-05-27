# modules/monitoring/outputs.tf
output "sns_topic_arn"    {
  value = aws_sns_topic.alarm.arn
}

output "dashboard_url"   {
  value = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "lambda_arn"      {
  value = aws_lambda_function.slack_notification.arn
}

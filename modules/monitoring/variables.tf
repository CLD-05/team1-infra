# modules/monitoring/variables.tf
variable "env"                {
  description = "환경명 (dev/prod)"
}
variable "slack_webhook_url" {
  description = "Slack Incoming Webhook URL"
  sensitive   = true
}

variable "eks_cluster_name"   {
  description = "EKS 클러스터명 (CloudWatch 메트릭 차원)"
}
variable "rds_instance_id"    {
  description = "RDS 인스턴스 ID (CloudWatch 메트릭 차원)"
}
variable "rds_max_connections" {
  description = "RDS 최대 커넥션 수 알람 임계치"
  default     = 100
}

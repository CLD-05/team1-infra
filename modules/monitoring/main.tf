# modules/monitoring/main.tf

# 생성 리소스:
# Monitoring 모듈
# - CloudWatch 대시보드
# - CloudWatch Metric Alarm (EKS, RDS, ALB)
# - SNS Topic
# - Lambda (SNS → Slack Webhook 전달)


# SNS Topic (알람 수신)
resource "aws_sns_topic" "alarm" {
  name = "${var.env}-alarm-topic"
  tags = { Name = "${var.env}-alarm-topic" }
}

# Lambda (SNS → Slack 전달)
# Lambda 실행 IAM Role
resource "aws_iam_role" "lambda_slack" {
  name = "${var.env}-lambda-slack-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_slack.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda 함수 코드
data "archive_file" "slack_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda_slack.zip"

  source {
    content  = <<-PYTHON
import json
import urllib.request
import os

def handler(event, context):
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    
    for record in event['Records']:
        sns_message = json.loads(record['Sns']['Message'])
        
        alarm_name  = sns_message.get('AlarmName', 'Unknown')
        state       = sns_message.get('NewStateValue', 'Unknown')
        reason      = sns_message.get('NewStateReason', '')
        
        # 상태별 이모지
        emoji = ':red_circle:' if state == 'ALARM' else ':large_green_circle:'
        
        payload = {
            'text': f'{emoji} *[{alarm_name}]* {state}\n>{reason}'
        }
        
        data = json.dumps(payload).encode('utf-8')
        req  = urllib.request.Request(
            webhook_url,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        urllib.request.urlopen(req)
    
    return {'statusCode': 200}
PYTHON
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "slack_notification" {
  function_name    = "${var.env}-slack-notification"
  role             = aws_iam_role.lambda_slack.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.slack_lambda.output_path
  source_code_hash = data.archive_file.slack_lambda.output_base64sha256

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = { Name = "${var.env}-slack-notification" }
}

# Lambda → SNS 트리거 연결
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notification.arn
}

# SNS가 Lambda 호출할 수 있는 권한
resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alarm.arn
}



# CloudWatch Alarm — EKS

# EKS 노드 CPU 사용률 80% 초과 시 알람
resource "aws_cloudwatch_metric_alarm" "eks_cpu_high" {
  alarm_name          = "${var.env}-eks-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2                        # 2번 연속 측정
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300                      # 5분 단위
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS 노드 CPU 80% 초과"

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]      # 정상 복구 시에도 알림

  tags = { Name = "${var.env}-eks-cpu-high" }
}

# EKS 노드 메모리 사용률 80% 초과 시 알람
resource "aws_cloudwatch_metric_alarm" "eks_memory_high" {
  alarm_name          = "${var.env}-eks-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS 노드 메모리 80% 초과"

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = { Name = "${var.env}-eks-memory-high" }
}



# CloudWatch Alarm — RDS

# RDS CPU 사용률 80% 초과 시 알람
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.env}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU 80% 초과"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = { Name = "${var.env}-rds-cpu-high" }
}

# RDS 여유 스토리지 10GB 미만 시 알람
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.env}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240             # 10GB (bytes)
  alarm_description   = "RDS 여유 스토리지 10GB 미만"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alarm.arn]

  tags = { Name = "${var.env}-rds-storage-low" }
}

# RDS DB 커넥션 수 초과 시 알람
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.env}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_max_connections
  alarm_description   = "RDS 커넥션 수 임계치 초과"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = { Name = "${var.env}-rds-connections-high" }
}

# CloudWatch 대시보드
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.env}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # EKS CPU
      {
        type       = "metric"
        x          = 0
        y          = 0
        width      = 12
        height     = 6
        properties = {
          title   = "EKS Node CPU Utilization"
          metrics = [["ContainerInsights", "node_cpu_utilization", "ClusterName", var.eks_cluster_name]]
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
        }
      },
      # EKS Memory
      {
        type       = "metric"
        x          = 12
        y          = 0
        width      = 12
        height     = 6
        properties = {
          title   = "EKS Node Memory Utilization"
          metrics = [["ContainerInsights", "node_memory_utilization", "ClusterName", var.eks_cluster_name]]
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
        }
      },
      # RDS CPU
      {
        type       = "metric"
        x          = 0
        y          = 6
        width      = 12
        height     = 6
        properties = {
          title   = "RDS CPU Utilization"
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id]]
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
        }
      },
      # RDS Connections
      {
        type       = "metric"
        x          = 12
        y          = 6
        width      = 12
        height     = 6
        properties = {
          title   = "RDS Database Connections"
          metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_id]]
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
        }
      }
    ]
  })
}

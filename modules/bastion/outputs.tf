# modules/bastion/outputs.tf

output "public_ip" {
  value = aws_instance.bastion.public_ip
}

output "instance_id" {
  value = aws_instance.bastion.id
}

output "security_group_id" {
  value = aws_security_group.bastion.id
}

# key_name 제거 (SSM 방식으로 변경)

output "role_arn" {
  value = aws_iam_role.bastion.arn
}

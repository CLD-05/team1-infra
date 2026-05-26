# modules/vpc/outputs.tf
#
# 출력값:
#   - vpc_id            : VPC ID (다른 모듈에서 참조)
#   - public_subnet_ids : 퍼블릭 서브넷 ID 목록 (Bastion 배치)
#   - private_subnet_ids: 프라이빗 서브넷 ID 목록 (EKS 노드 배치)
#   - nat_gateway_ip    : NAT GW 퍼블릭 IP (방화벽 화이트리스트용)

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_ip" {
  value       = aws_eip.nat[*].public_ip
  description = "NAT Gateway 퍼블릭 IP 목록"
}

output "isolated_subnet_ids" {
  value = aws_subnet.isolated[*].id
}

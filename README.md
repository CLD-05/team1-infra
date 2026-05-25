# bootstrap apply 실행 
- 초기 실행 1번만 진행. s3, DynamoDB 리소스 남길 시 terraform destroy X
---

```
cd bootstrap
terraform init
terraform validate
terraform plan
terraform apply
```

# terraform apply 후 AWS 리소스 확인 목록

---

## 1. VPC

```
VPC → team1-vpc 확인
서브넷 6개 확인
├── Public Subnet × 2 (10.0.1.0/24, 10.0.2.0/24)
├── Private Subnet × 2 (10.0.3.0/24, 10.0.4.0/24)
└── Isolated Subnet × 2 (10.0.5.0/24, 10.0.6.0/24)
NAT Gateway × 1 확인
Internet Gateway × 1 확인
Elastic IP × 1 확인
```

---

## 2. EKS

```
EKS → team1-cluster 확인
노드 그룹 → general (2대) 확인
kubectl get nodes → Ready 상태 확인
```

---

## 3. EC2 (Bastion)

```
EC2 → team1-bastion 확인
Running 상태 확인
IAM Role → team1-bastion-role 확인
SSM Session Manager 접속 확인
```

---

## 4. RDS

```
RDS → team1-rds-primary 확인
RDS → team1-rds-replica 확인
상태: Available 확인
Isolated Subnet 배치 확인
Multi-AZ: false 확인 (Day6 시연 전 true로 변경)
```

---

## 5. ElastiCache

```
ElastiCache → team1-redis 확인
상태: Available 확인
Isolated Subnet 배치 확인
```

---

## 6. ECR

```
ECR → course-service 확인
ECR → enroll-service 확인
이미지 스캔 활성화 확인
IMMUTABLE 태그 확인
```

---

## 7. IAM

```
IAM Roles 확인
├── team1-cluster-alb-controller  (ALB Controller IRSA)
├── team1-cluster-ebs-csi-driver  (EBS CSI IRSA)
├── team1-cluster-eso             (ESO IRSA)
├── team1-bastion-role            (Bastion EC2)
└── github-actions-terraform-role (GitHub Actions OIDC)

IAM OIDC Provider 확인
├── token.actions.githubusercontent.com (GitHub Actions)
└── EKS OIDC Provider
```

---

## 8. S3 + DynamoDB (bootstrap)

```
S3 → team1-terraform-state 확인
버저닝 활성화 확인
DynamoDB → terraform-lock 확인
```

---

## 9. Security Group

```
team1-bastion-sg → SSH 22 (로컬) 또는 인바운드 없음 (SSM)
team1-rds-sg     → 3306 EKS 노드, Bastion에서만 허용
team1-redis-sg   → 6379 EKS 노드에서만 허용
EKS 클러스터 SG  → 443 Bastion에서만 허용
```

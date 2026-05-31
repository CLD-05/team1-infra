# team1-infra

> EKS 기반 수강신청 시스템 인프라 — Terraform IaC
 


### 관련 레포지토리

| 구분 | URL |
|------|-----|
| App (소스코드) | https://github.com/CLD-05/team1-app |
| Config (k8s 매니페스트) | https://github.com/CLD-05/team1-config |
| Infra (현재) | https://github.com/CLD-05/team1-infra |
 
---

### 디렉터리 구조

```aiignore
infra/
│
├── bootstrap         
│   ├── main.tf       
│   ├── outputs.tf    
│   └── providers.tf  
│
├── modules/
│   ├── vpc/         
│   ├── ecr/          
│   ├── github-oidc/
│   ├── eks/         
│   ├── rds/          
│   ├── cloudfront/   
│   ├── monitoring/  
│   └── bastion/      
│
└── envs/
    ├── dev/                # 개발 환경    
    └── prod/               # 운영 환경


```

<br>

---

### 사전 요구사항

| 도구 | 버전    | 설치 |
|------|-------|------|
| Terraform | 1.x+  | `brew install terraform` |
| AWS CLI | 2.x+  | `brew install awscli` |

<br>

### 환경별 주요 설정값

| 항목           | Dev          | Prod         |
|--------------|--------------|--------------|
| EKS 노드 타입    | t3.medium    | t3.medium    |
| EKS 노드 수     | 2~10         | 2~10         |
| RDS 인스턴스     | db.t3.medium | db.t3.medium |
| RDS Multi-AZ | false        | true         |
| NAT GW       | 1개 (비용 절감)   | 2개 (고가용성)    |
| WAF          | 5000         | 2000         |
| ECR 이미지 보관   | 10개          | 10개          |

<br>

---

## 실행 방법

---

### 0. SSM Parameter 등록 (최초 1회)
민감한 값은 코드에 포함하지 않고 SSM에 저장

```bash
aws eks update-kubeconfig \
  --region $AWS_REGION \
  --name team1-cluster
---
aws ssm put-parameter \
  --name "/team1/eks-dev/db-password" \
  --value '비밀번호' \
  --type SecureString \
  --region $AWS_REGION

aws ssm put-parameter \
  --name "/team1/eks-dev/db-username" \
  --value '값' \
  --type SecureString \
  --region $AWS_REGION
  
aws ssm put-parameter \
  --name "/team1/eks-dev/slack-webhook" \
  --value "주소값" \
  --type SecureString \
  --region $AWS_REGION \
  --profile team1-lye-mfa
```

---
### 1. bootstrap apply 실행
초기 실행 1번만 진행. S3, DynamoDB 리소스 남길 시 terraform destroy X


```
cd bootstrap
terraform init
terraform validate
terraform plan
terraform apply
```

<br>

### 2. terraform apply 후 AWS 리소스 확인 목록

---

### VPC

Dev (VPC: 10.1.0.0/16)

| 서브넷 | AZ | CIDR | 용도 |
|--------|-----|------|-----|
| Public | 2a | 10.1.0.0/24 | NAT GW, Bastion |
| Public | 2c | 10.1.1.0/24 | NAT GW |
| Private | 2a | 10.1.4.0/22 | EKS Worker Node |
| Private | 2c | 10.1.8.0/22 | EKS Worker Node |
| Isolated | 2a | 10.1.20.0/24 | RDS |
| Isolated | 2c | 10.1.21.0/24 | RDS |
NAT Gateway × 1 확인 \
Internet Gateway × 1 확인 \
Elastic IP × 1 확인

<br>

Prod (VPC: 10.0.0.0/16)

| 서브넷 | AZ | CIDR | 용도 |
|--------|-----|------|-----|
| Public | 2a | 10.0.0.0/24 | NAT GW, Bastion |
| Public | 2c | 10.0.1.0/24 | NAT GW |
| Private | 2a | 10.0.4.0/22 | EKS Worker Node |
| Private | 2c | 10.0.8.0/22 | EKS Worker Node |
| Isolated | 2a | 10.0.20.0/24 | RDS |
| Isolated | 2c | 10.0.21.0/24 | RDS |

NAT Gateway × 2 확인 \
Internet Gateway × 1 확인 \
Elastic IP × 2 확인


---

### EKS

```
EKS → team1-cluster 확인
노드 그룹 → general (2대) 확인
kubectl get nodes → Ready 상태 확인
```

---

### EC2 (Bastion)

```
EC2 → team1-bastion 확인
Running 상태 확인
IAM Role → team1-bastion-role 확인
SSM Session Manager 접속 확인
```

---

### RDS

```
RDS → team1-rds-primary 확인
RDS → team1-rds-replica 확인
상태: Available 확인
Isolated Subnet 배치 확인
Multi-AZ: false 확인 (prod 환경에서 true로 변경)
```
---

### ECR

```
ECR → course-service 확인
ECR → enroll-service 확인
이미지 스캔 활성화 확인
IMMUTABLE 태그 확인
```

---

### IAM

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

### S3 + DynamoDB (bootstrap)

```
S3 → team1-terraform-state 확인
버저닝 활성화 확인
DynamoDB → terraform-lock 확인
```

---

### Security Group

```
team1-bastion-sg → SSH 22 (로컬) 또는 인바운드 없음 (SSM)
team1-rds-sg     → 3306 EKS 노드, Bastion에서만 허용
team1-redis-sg   → 6379 EKS 노드에서만 허용
EKS 클러스터 SG  → 443 Bastion에서만 허용
```

---

### CloudFront

```
CloudFront Distribution 확인
├── Status: Deployed 확인
├── Origin1: ALB DNS (동적 콘텐츠 — Spring Boot)
├── Origin2: S3 버킷 (정적 리소스 — /static/*)
├── HTTP → HTTPS 리다이렉트 확인
└── WAF WebACL 연결 확인
 
ACM 인증서 확인 (us-east-1)
├── 상태: Issued 확인
└── DNS 검증 완료 확인
 
WAF 확인 (us-east-1)
├── AWSManagedRulesCommonRuleSet 활성화 확인
└── RateLimitRule 활성화 확인
    dev:  5,000 req / 5min
    prod: 2,000 req / 5min
 
S3 버킷 확인
├── 퍼블릭 액세스 차단 확인
└── OAC 정책 적용 확인
 
Route53 확인
└── 커스텀 도메인 → CloudFront Alias 레코드 확인
```
 
---

### Monitoring

```
SNS 확인
└── SNS Topic → team1-alarm-topic 확인
 
Lambda 확인
├── 함수명 → team1-slack-notification 확인
├── Runtime: Python 3.12 확인
└── SNS 트리거 연결 확인
 
CloudWatch Alarm 확인 (총 5개)
├── EKS CPU    → eks-cpu-high    (임계값: 80%)
├── EKS Memory → eks-memory-high (임계값: 80%)
├── RDS CPU    → rds-cpu-high    (임계값: 80%)
├── RDS Storage → rds-storage-low (임계값: 10GB 미만)
└── RDS Connections → rds-connections-high
 
CloudWatch Dashboard 확인
└── team1-dashboard → EKS/RDS 메트릭 시각화 확인
 
Slack 알람 테스트
└── SNS → Lambda → Slack 메시지 수신 확인
```
 
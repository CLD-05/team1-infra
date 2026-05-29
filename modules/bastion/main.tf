# 키 페어 참조 (use_ssm = false일 때만)
data "aws_key_pair" "bastion" {
  count    = var.use_ssm ? 0 : 1
  key_name = var.key_name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

# 보안그룹
resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion-sg"
  description = "Bastion EC2 Security Group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.use_ssm ? [] : [1]
    content {
      description = "SSH from my IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-bastion-sg"
  }
}

# EC2
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = true
  key_name                    = var.use_ssm ? null : data.aws_key_pair.bastion[0].key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y unzip curl jq

    # AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
      -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip

    # kubectl
    KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/$${KUBECTL_VER}/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl

    # helm
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # SSM Agent (use_ssm = true일 때만)
    if [ "${var.use_ssm}" = "true" ]; then
      snap install amazon-ssm-agent --classic
      systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
      systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
    fi

    echo "Bastion 초기화 완료: $(date)" >> /var/log/bastion-init.log
    aws --version >> /var/log/bastion-init.log 2>&1
    kubectl version --client >> /var/log/bastion-init.log 2>&1
    helm version --short >> /var/log/bastion-init.log 2>&1
    EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project}-bastion"
  }
}

# IAM
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project}-bastion-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name = "${var.project}-bastion-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_eks" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy" "bastion_eks_access" {
  name = "${var.project}-bastion-eks-access"
  role = aws_iam_role.bastion.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster", "eks:ListClusters"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "bastion_ecr_access" {
  name = "${var.project}-bastion-ecr-access"
  role = aws_iam_role.bastion.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:DescribeRepositories",
        "ecr:ListImages"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "bastion_iam_read" {
  name = "${var.project}-bastion-iam-read"
  role = aws_iam_role.bastion.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:GetRole",
        "iam:ListRoles",
        "iam:GetRolePolicy",
        "iam:ListAttachedRolePolicies"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "bastion_ssm_write" {
  name = "${var.project}-bastion-ssm-write"
  role = aws_iam_role.bastion.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:PutParameter",
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath",
        "ssm:DeleteParameter"
      ]
      # data source로 account ID 자동 참조
      Resource = [
        "arn:aws:ssm:ap-northeast-2:${data.aws_caller_identity.current.account_id}:parameter/team1",
        "arn:aws:ssm:ap-northeast-2:${data.aws_caller_identity.current.account_id}:parameter/team1/*"
      ]
    }]
  })
}

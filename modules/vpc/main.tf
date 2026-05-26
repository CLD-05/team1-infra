# modules/vpc/main.tf
#
# 생성 리소스:
#   - aws_vpc                      : VPC (DNS Hostname/Support 활성화)
#   - aws_internet_gateway         : IGW (퍼블릭 서브넷 인터넷 연결)
#   - aws_subnet (public x2)       : 퍼블릭 서브넷 (Bastion, NAT GW 배치)
#   - aws_subnet (private x2)      : 프라이빗 서브넷 (EKS 노드 배치)
#   - aws_eip                      : NAT Gateway용 고정 퍼블릭 IP
#   - aws_nat_gateway              : NAT GW (프라이빗 서브넷 아웃바운드)
#   - aws_route_table (public)     : 퍼블릭 RT (0.0.0.0/0 -> IGW)
#   - aws_route_table (private)    : 프라이빗 RT (0.0.0.0/0 -> NAT GW)
#   - aws_route_table_association  : 서브넷-RT 연결 (public x2, private x2)

locals {
  public_count  = length(var.public_cidrs)
  private_count = length(var.private_cidrs)
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name                                        = "${var.project}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-igw"
  }
}


#  "kubernetes.io/role/elb"                    = "1" => elb가 붙을 수있음
resource "aws_subnet" "public" {
  count                   = local.public_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "${var.project}-public-subnet-${var.azs[count.index]}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private" {
  count             = local.private_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    Name                                        = "${var.project}-private-subnet-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_eip" "nat" {
  count      = var.enable_nat_per_az ? local.public_count : 1
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  tags = {
    Name = "${var.project}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_per_az ? local.public_count : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]
  tags = {
    Name = "${var.project}-natgw-${count.index}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = local.public_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = var.enable_nat_per_az ? local.private_count : 1
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_per_az ? aws_nat_gateway.main[count.index].id : aws_nat_gateway.main[0].id
  }
  tags = {
    Name = "${var.project}-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count          = local.private_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_per_az ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

# modules/vpc/main.tf에 추가
resource "aws_subnet" "isolated" {
  count             = length(var.isolated_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.isolated_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    Name = "${var.project}-isolated-subnet-${var.azs[count.index]}"
  }
}

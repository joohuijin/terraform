# 최신 Amazon Linux 2023 AMI 조회 (리전 종속 문제 회피)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # 내부 DNS 해석
  enable_dns_hostnames = true # DNS 호스트네임
  tags                 = { Name = "mp2-vpc" }
}

# 퍼블릭 서브넷 x2 (AZ a, c)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true # 퍼블릭 IP 자동 할당
  tags                    = { Name = "mp2-public-${count.index + 1}" }
}

# 프라이빗 서브넷 x2 (AZ a, c)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = { Name = "mp2-private-${count.index + 1}" }
}

# 인터넷 게이트웨이 (퍼블릭 외부통신)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "mp2-igw" }
}

# NAT 게이트웨이용 EIP
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "mp2-nat-eip" }
}

# NAT 게이트웨이 (프라이빗 아웃바운드, 비용 위해 1개만)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "mp2-nat" }
  depends_on    = [aws_internet_gateway.igw]
}

# 퍼블릭 라우팅 테이블 (0.0.0.0/0 -> IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "mp2-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 프라이빗 라우팅 테이블 (0.0.0.0/0 -> NAT GW)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "mp2-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# web 모듈 (ALB + ASG)
module "web" {
  source = "./modules/web"

  vpc_id             = aws_vpc.main.id
  public_subnet_ids  = aws_subnet.public[*].id  # ALB 배치용
  private_subnet_ids = aws_subnet.private[*].id # ASG(EC2) 배치용
  ami_id             = data.aws_ami.al2023.id
  instance_type      = var.instance_type
  key_name           = var.key_name
}

# db 모듈 (MySQL EC2 x2)
module "db" {
  source = "./modules/db"

  vpc_id             = aws_vpc.main.id
  private_subnet_ids = aws_subnet.private[*].id
  ami_id             = data.aws_ami.al2023.id
  instance_type      = var.instance_type
  key_name           = var.key_name
  web_sg_id          = module.web.web_sg_id # 웹 SG 에서 오는 3306 만 허용
}

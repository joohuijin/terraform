# ── Provider ─────────────────────────────
provider "aws" {
  region = "us-east-2" # 사용 리전에 맞게 변경
}

# ── Parameters 대응 ──────────────────────
# KeyName: 실행 시 주입할 기존 KeyPair 이름
variable "key_name" {
  description = "SSH 접속용 기존 EC2 KeyPair 이름"
  type        = string
}

# LatestAmiId: SSM 공개 파라미터에서 최신 Amazon Linux 2 AMI ID 조회
data "aws_ssm_parameter" "latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# !GetAZs 대응: 현재 리전의 사용 가능한 AZ 목록 조회
data "aws_availability_zones" "available" {
  state = "available"
}

# ── VPC ──────────────────────────────────
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "My-VPC" }
}

# ── Internet Gateway (생성 + VPC 연결 동시) ─
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id
  tags   = { Name = "My-IGW" }
}

# ── Public Route Table + 기본 경로 ───────
resource "aws_route_table" "myPublicRT" {
  vpc_id = aws_vpc.myVPC.id
  tags   = { Name = "My-Public-RT" }
}

resource "aws_route" "myDefaultPublicRoute" {
  route_table_id         = aws_route_table.myPublicRT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.myIGW.id
}

# ── Public Subnet ×2 (AZ 분산) ───────────
resource "aws_subnet" "myPublicSN1" {
  vpc_id            = aws_vpc.myVPC.id
  availability_zone = data.aws_availability_zones.available.names[0] # 첫 번째 AZ
  cidr_block        = "10.0.0.0/24"
  tags              = { Name = "My-Public-SN-1" }
}

resource "aws_subnet" "myPublicSN2" {
  vpc_id            = aws_vpc.myVPC.id
  availability_zone = data.aws_availability_zones.available.names[2] # 세 번째 AZ (CFN 원본 index 2 유지)
  cidr_block        = "10.0.1.0/24"
  tags              = { Name = "My-Public-SN-2" }
}

resource "aws_route_table_association" "assoc1" {
  route_table_id = aws_route_table.myPublicRT.id
  subnet_id      = aws_subnet.myPublicSN1.id
}

resource "aws_route_table_association" "assoc2" {
  route_table_id = aws_route_table.myPublicRT.id
  subnet_id      = aws_subnet.myPublicSN2.id
}

# ── Security Group (HTTP 80 / SSH 22) ────
resource "aws_security_group" "websg" {
  name        = "WEBSG"
  description = "Enable HTTP access via port 80 and SSH access via port 22"
  vpc_id      = aws_vpc.myVPC.id
  tags        = { Name = "WEBSG" }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # CFN은 egress 미지정 시 전체 허용이 기본. Terraform은 미지정 시 egress를 제거하므로
  # 동일 동작을 위해 전체 아웃바운드 허용을 명시적으로 추가
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── EC2 인스턴스 ×2 ──────────────────────
resource "aws_instance" "ec2_1" {
  ami                         = data.aws_ssm_parameter.latest_ami.value
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.myPublicSN1.id
  vpc_security_group_ids      = [aws_security_group.websg.id]
  associate_public_ip_address = true # NetworkInterfaces의 AssociatePublicIpAddress 대응
  tags                        = { Name = "EC2-1" }

  # UserData: 부팅 시 httpd 설치·기동, 테스트 페이지 생성
  user_data = <<-EOF
    #!/bin/bash
    hostname EC2-1
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    echo "<h1>CloudNet@ EC2-1 Web Server</h1>" > /var/www/html/index.html
  EOF
}

resource "aws_instance" "ec2_2" {
  ami                         = data.aws_ssm_parameter.latest_ami.value
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.myPublicSN2.id
  vpc_security_group_ids      = [aws_security_group.websg.id]
  associate_public_ip_address = true
  tags                        = { Name = "EC2-2" }

  user_data = <<-EOF
    #!/bin/bash
    hostname ELB-EC2-2
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    echo "<h1>CloudNet@ EC2-2 Web Server</h1>" > /var/www/html/index.html
  EOF
}

# ── EIP ×2 + 연결 ────────────────────────
resource "aws_eip" "eip1" {
  domain = "vpc" # 구버전의 vpc = true 를 대체하는 현재 문법
}
resource "aws_eip_association" "eip1_assoc" {
  instance_id   = aws_instance.ec2_1.id
  allocation_id = aws_eip.eip1.id # VPC EIP는 id가 곧 allocation_id
}

resource "aws_eip" "eip2" {
  domain = "vpc"
}
resource "aws_eip_association" "eip2_assoc" {
  instance_id   = aws_instance.ec2_2.id
  allocation_id = aws_eip.eip2.id
}

# ── ALB: Target Group ────────────────────
resource "aws_lb_target_group" "alb_tg" {
  name     = "My-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myVPC.id
  # target_type 기본값 "instance" → CFN 기본 동작과 동일
}

# CFN은 TargetGroup 안에 Targets를 인라인 지정하지만
# Terraform은 타깃 등록을 별도 리소스(attachment)로 분리
resource "aws_lb_target_group_attachment" "tg_ec2_1" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.ec2_1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "tg_ec2_2" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.ec2_2.id
  port             = 80
}

# ── ALB: Load Balancer ───────────────────
resource "aws_lb" "alb" {
  name               = "My-ALB"
  internal           = false # Scheme: internet-facing 대응
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]
  subnets            = [aws_subnet.myPublicSN1.id, aws_subnet.myPublicSN2.id]
}

# ── ALB: Listener (80 → TG 포워딩) ───────
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

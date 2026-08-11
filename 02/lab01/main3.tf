# 작업계획 
# * NAT Gateway 생성(publicSN)
# * Private Subnet 생성
# * private Routing table 생성 및 연결 
# * SG 생성
# * EC2 생성

# 1) NAT Gateway 생성(publicSN)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
# * EIP 생성
# * Public Subnet에 NAT Gateway 생성 
resource "aws_eip" "myEIP" {
  domain = "vpc"

  tags = {
    Name = "myEIP"
  }
}
resource "aws_nat_gateway" "myNAT-GW" {
  allocation_id = aws_eip.myEIP.id
  subnet_id     = aws_subnet.myPubSN.id

  tags = {
    Name = "myNAT-GW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.myIGW]
}
# 2) Private Subnet 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# * 새로 생성된 myVPC에 놓아야 한다. 
resource "aws_subnet" "myPriSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "myPriSN"
  }
}
# 3) private Routing table 생성 및 연결 
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table" "myPriRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.myNAT-GW.id
  }

  tags = {
    Name = "myPriRT"
  }
}
resource "aws_route_table_association" "myPriRTassoc" {
  subnet_id      = aws_subnet.myPriSN.id
  route_table_id = aws_route_table.myPriRT.id
}
# 4) SG 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# * SG (22/tcp, 80/tcp, 443/tcp)

resource "aws_security_group" "myPriSN" {
  name        = "myPriSN"
  description = "Allow SSH,WEB inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "myPriSN"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.myPriSN.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.myPriSN.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.myPriSN.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.myPriSN.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
# 5) EC2 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
# * 새로 생성된 SG 사용 =>  vpc_security_group_ids  
# * mykeypair 넣기 =>  key_name 
# 새로 생성된 myPriSN에 놓아야 한다. => subnet_id 
# * user_data -> user_data_replace-on_change [v]
resource "aws_instance" "myPriEC2" {
  ami                         = "ami-048f644e868baa0e8"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.myPriSN.id]
  key_name                    = "mykeypair"
  subnet_id                   = aws_subnet.myPriSN.id
  user_data_replace_on_change = true
  user_data                   = <<-EOF
        #!/bin/bash
        dnf install -y httpd mod_ssl
        echo "My Web Server 2 Test Page" > /var/www/html/index.html
        systemctl enable --now httpd
        EOF

  tags = {
    Name = "myPriEC2"
  }
}
provider "aws" {
  region = "us-east-2"
}
# EC2 Instance + Web Server 생성
# * SG(8080/tcp)
# * EC2 생성(user_data)

# 1) SG 생성
resource "aws_security_group" "allow_8080" {
  name        = "allow_8080"
  description = "Allow 8080/tcp inbound traffic and all outbound traffic"


  tags = {
    Name = "allow_8080"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_web" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "myinstance" {
  ami           = "ami-0e5497a77ef21b5ac"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.allow_8080.id]

  user_data_replace_on_change = true
  user_data                   = <<-EOF
  #!/bin/bash
  echo "<h1>MyWeb</h1>" > index.html
  nohup busybox httpd -f -p 8080 &
  EOF

  tags = {
    Name = "myEC2"
  }
}

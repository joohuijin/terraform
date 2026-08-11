#
# Provider 
#
provider "aws" {
  region = "us-east-2"
}

#
# VPC(IGW), PubSubnet(PubRT)
#
# * VPC 생성 
# * IGW 생성과 VPC 연결 
# * PubSubnet 생성 
# * PubPT 생성 및 설정, 연결 

# 1) VPC 생성 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
# * dns_hostname name 
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}
# 2) IGW 생성과 VPC 연결 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}
# 3) PubSubnet 생성 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# * 퍼블릭 ipv4 주소 자동 할당 자동화 [v]
resource "aws_subnet" "myPubSN" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSN"
  }
}

# 4) PubPT 생성 및 설정, 연결 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# * default route -> myIGW
# * myPubRT에 연결
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}

resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubRT.id
}
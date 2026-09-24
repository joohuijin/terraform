
provider "aws" {
  region = "us-east-2"
}
#
# Web Server
# ALB - TG(ASG)
#
# 1. Default VPC
# 2. ALB - TG(ASG)
# 1) ALB 생성
#   * TG 생성
#   * SG 생성 (LB가 사용)
#   * LB 생성
#   * LB Listener 생성
#   * LB Listener rule 생성
# 2) ASG 생성
#   * SG 생성
#   * LT 생성(mykeypair, user_data)
#   * ASG 생성

# 1. Default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
# 2. ALB - TG(ASG)
data "terraform_remote_state" "myRemoteState" {
  backend = "s3"
  config = {
    bucket = "bucket-jhj-0204"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

# 1) ALB 생성
#   * SG 생성 (LB가 사용)
resource "aws_security_group" "myLB_SG" {
  name        = "myLB_SG"
  description = "Allow 80/tcp inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myLB_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.myLB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.myLB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
#   * TG 생성
resource "aws_lb_target_group" "myLB_TG" {
  name     = "myLB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}
#   * LB 생성
resource "aws_lb" "myLB" {
  name               = "myLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myLB_SG.id]
  subnets            = data.aws_subnets.default.ids

}
#   * LB Listener 생성
resource "aws_lb_listener" "myLB_Listener" {
  load_balancer_arn = aws_lb.myLB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myLB_TG.arn
  }
}
#   * LB Listener rule 생성
resource "aws_lb_listener_rule" "myLB_Listener_rule" {
  listener_arn = aws_lb_listener.myLB_Listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myLB_TG.id
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
# 2) ASG 생성
#   * SG 생성
#   * LT 생성(mykeypair, user_data)
data "aws_ami" "amz2023ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.18-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

resource "aws_launch_template" "myLT" {
  name                   = "myLT"
  image_id               = data.aws_ami.amz2023ami.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.myLB_SG.id]
  user_data = base64encode(templatefile("userdata.sh", {
    db_address = data.terraform_remote_state.myRemoteState.outputs.dbIP
    db_port    = data.terraform_remote_state.myRemoteState.outputs.dbPort
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "myLT"
    }
  }


}
#   * ASG 생성
# - target_group
# - depends_on

resource "aws_autoscaling_group" "bar" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  desired_capacity    = 2
  max_size            = 10
  min_size            = 1

  target_group_arns = [aws_lb_target_group.myLB_TG.arn]
  depends_on        = [aws_lb_target_group.myLB_TG]
  launch_template {
    id      = aws_launch_template.myLT.id
    version = "1"
  }
}

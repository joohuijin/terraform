# ALB 보안그룹: 외부 -> 80
resource "aws_security_group" "alb" {
  name   = "mp2-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "mp2-alb-sg" }
}

# 웹(WAS) 보안그룹: ALB SG 에서 오는 80 만 허용
resource "aws_security_group" "web" {
  name   = "mp2-web-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # SG 참조로 계층 격리
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "mp2-web-sg" }
}

# 시작 템플릿: httpd + php 설치·기동
resource "aws_launch_template" "web" {
  name_prefix            = "mp2-web-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  # launch_template 의 user_data 는 base64 인코딩 필수
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd php php-fpm        # 웹서버 + php
    systemctl enable --now httpd php-fpm    # 부팅 자동기동 + 즉시 실행
    # 헬스체크용 index (호스트네임 표시)
    echo "<h1>WEB/WAS $(hostname -f)</h1>" > /var/www/html/index.html
    # php 동작 확인용 (선택)
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "mp2-web" }
  }
}

# 타겟 그룹: 80 포트, "/" 헬스체크
resource "aws_lb_target_group" "web" {
  name     = "mp2-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/" # index.html 확인
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
  }
  tags = { Name = "mp2-web-tg" }
}

# ALB: 퍼블릭 서브넷, 인터넷 대면
resource "aws_lb" "web" {
  name               = "mp2-alb"
  internal           = false # 인터넷 대면
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  tags               = { Name = "mp2-alb" }
}

# 리스너: 80 -> 타겟 그룹 포워딩
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ASG: 프라이빗 서브넷에 EC2 2대, TG 연결
resource "aws_autoscaling_group" "web" {
  name                = "mp2-web-asg"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = var.private_subnet_ids # 프라이빗 2개에 분산
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB" # ELB 헬스체크 기준

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "mp2-web"
    propagate_at_launch = true
  }
}

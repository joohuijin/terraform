# DB 보안그룹: 웹 SG 에서 오는 3306 만 허용
resource "aws_security_group" "db" {
  name   = "mp2-db-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "MySQL from web only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.web_sg_id] # 웹 계층만 접근 허용
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "mp2-db-sg" }
}

# DB EC2 x2 (프라이빗 서브넷에 AZ 분산)
resource "aws_instance" "db" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index] # AZ별 배치
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.db.id]

  # aws_instance 의 user_data 는 평문 (Terraform 이 base64 처리)
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y mariadb105-server     # MySQL 호환 MariaDB (AL2023 패키지)
    systemctl enable --now mariadb       # 부팅 자동기동 + 즉시 실행
  EOF

  tags = { Name = "mp2-db-${count.index + 1}" }
}

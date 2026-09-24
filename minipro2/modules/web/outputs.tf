output "alb_dns_name" {
  description = "ALB 접속 주소"
  value       = aws_lb.web.dns_name
}

output "web_sg_id" {
  description = "웹 SG ID (DB 모듈에서 3306 소스로 참조)"
  value       = aws_security_group.web.id
}

# modules/db/outputs.tf — db 모듈 자체 출력만
output "db_private_ips" {
  description = "DB 인스턴스 프라이빗 IP 목록"
  value       = aws_instance.db[*].private_ip # 이 모듈 내부 리소스 참조
}

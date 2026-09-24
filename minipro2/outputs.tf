# outputs.tf (루트) — 모듈 호출 결과 참조
output "alb_dns_name" {
  description = "웹 접속 주소 (브라우저 확인)"
  value       = module.web.alb_dns_name
}

output "db_private_ips" {
  value = module.db.db_private_ips
}

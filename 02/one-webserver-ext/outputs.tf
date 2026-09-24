output "public_IP" {
  value       = aws_instance.myinstance.public_ip
  description = "my EC2 Public IP"
}

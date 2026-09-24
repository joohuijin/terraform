# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Output declarations
# VPC_id
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "New VPC ID"
}

# LB DNS name:
output "lb_url" {
  value       = "http://${module.elb_http.elb_dns_name}/"
  description = "LB DNS name"
}

#EC2 Instance count
output "ec2_count" {
  value       = length(module.ec2_instances.instance_ids)
  description = "EC2 Count"
}

# DB username
output "db_username" {
  value       = aws_db_instance.database.username
  description = "DB username"
  sensitive   = true
}

# DB password
output "db_password" {
  value       = aws_db_instance.database.password
  description = "DE password"
  sensitive   = true
}

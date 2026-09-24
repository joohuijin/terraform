variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "key_name" { type = string }
variable "web_sg_id" { type = string } # 웹 SG (3306 허용 소스)

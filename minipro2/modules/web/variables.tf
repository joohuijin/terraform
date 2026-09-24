variable "vpc_id" { type = string }

variable "public_subnet_ids" { type = list(string) } # ALB 용

variable "private_subnet_ids" { type = list(string) } # ASG 용

variable "ami_id" { type = string }

variable "instance_type" { type = string }

variable "key_name" { type = string }

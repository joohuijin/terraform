variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_tag" {
  default = {
    Name = "main"
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "subnet_tag" {
  default = {
    Name = "Main"
  }
}

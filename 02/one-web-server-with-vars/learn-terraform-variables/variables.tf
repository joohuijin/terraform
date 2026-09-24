# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Variable declarations
variable "aws_region" {
  default     = "us-east-2"
  type        = string
  description = "AWS Region"
}

variable "vpc_cidr_block" {
  default     = "10.0.0.0/16"
  type        = string
  description = "AWS VPC CIDR Block"
}

variable "instance_count" {
  default     = 2
  type        = number
  description = "EC2 Instance Count"
}

variable "disable_vpn_gateway" {
  default     = false
  type        = bool
  description = "diasble VPN Gateway"
}
# variable "public_subnets" {
#     default = ["10.0.1.0/24", "10.0.2.0/24"]
#     type = list(string)
#     description = "Public subnets"
# }

variable "public_subnet_cidr_blocks" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24",
  ]
  type        = list(string)
  description = "Pblic Subnet CIDR Blocks"

}
variable "subnet_count" {
  default     = 2
  type        = number
  description = "subnet count"
}

variable "private_subnet_cidr_blocks" {
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24",
    "10.0.105.0/24",
    "10.0.106.0/24",
    "10.0.107.0/24",
    "10.0.108.0/24",
  ]
  type        = list(string)
  description = "Private Subnet CIDR Blocks"
}

variable "resource_tags" {
  default = {
    project     = "project-alpha",
    environment = "dev"
  }
  type        = map(string)
  description = "Resources Tags"
}

variable "ec2_instance_type" {
  description = "EC2 Instance Type(ex: t2.micro):"
  type        = string
}

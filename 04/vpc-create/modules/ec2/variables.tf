variable "amiid" {
  default = "ami-04ad6ded6cff6b818"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
}

variable "ec2_tag" {
  default = {
    Name = "HelloWorld"
  }
}

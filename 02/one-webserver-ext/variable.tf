variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "allow_8080"
}
variable "server_port" {
  default = 8080
}

variable "dbuser" {
  type        = string
  description = "Enter your dbuser(ex: dbuser):"
  sensitive   = true
}

variable "dbpassword" {
  type        = string
  description = "Enter your dbuser password:"
  sensitive   = true
}

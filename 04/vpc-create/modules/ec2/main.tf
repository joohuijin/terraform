resource "aws_instance" "example" {
  ami           = var.amiid
  subnet_id     = var.subnet_id
  instance_type = "t3.micro"

  tags = var.ec2_tag
}

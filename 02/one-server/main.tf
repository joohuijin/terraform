provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami           = "ami-048f644e868baa0e8"
  instance_type = "t3.micro"
  tags = {
    Name = "terraform-example"
  }
}


terraform {
  backend "s3" {
    bucket       = "bucket-jhj-0204"
    key          = "terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}


provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "myTFstate" {
  bucket        = "bucket-jhj-0204"
  force_destroy = true

  tags = {
    Name = "myTFstate"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.myTFstate.arn
}

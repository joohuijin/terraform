
provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "mybucket" {
  bucket        = "bucket-jhj-0204"
  force_destroy = true
  tags = {
    Name = "mybucket"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.mybucket.arn
}

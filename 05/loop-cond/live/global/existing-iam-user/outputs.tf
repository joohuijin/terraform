output "arns" {
  value = aws_iam_user.createuser[*].arn
}

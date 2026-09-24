provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_iam_user" "createuser" {
  # Make sure to update this to your own user name!
  count = length(var.user_names)
  name  = var.user_names[count.index]
}

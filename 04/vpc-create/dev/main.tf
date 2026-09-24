provider "aws" {
  region = "ap-northeast-2"
}

module "myVPC" {
  source = "../modules/vpc"

  vpc_id = module.myVPC.vpc_id
}

module "myec2" {
  source = "../modules/ec2"

  subnet_id = module.myVPC.subnet_id
}

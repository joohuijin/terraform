provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "myDB" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.dbuser
  password             = var.dbpassword
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

# DB IP/Port
# DB User/Password
# DB/Table
output "dbIP" {
  value = aws_db_instance.myDB.address
}
output "dbPort" {
  value = aws_db_instance.myDB.port
}

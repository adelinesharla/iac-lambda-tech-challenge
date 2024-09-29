variable "aws_region" {
  default = "us-east-1"
}

variable "db_password" {
  type      = string
  sensitive = true
  description = "Senha do usuário mestre do banco de dados Aurora"
}

variable "aws_iam_role" {
  default = "arn:aws:iam::717145188069:role/LabRole"
}
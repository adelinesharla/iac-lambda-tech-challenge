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

variable "bucket_name" {
  default = "terraform-state-tech-challenge-1"
}

variable "bucket_key" {
  default = "terraform-db/terraform.tfstate"
}
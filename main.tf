# Configuração do provedor AWS 
provider "aws" {
  region = var.aws_region 
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "banco_de_dados" {
  backend = "s3"

  config = {
    bucket = var.bucket_name
    key    = var.bucket_key
    region = "us-east-1"
  }
}

# Função Lambda
resource "aws_lambda_function" "authentication_lambda" {
  function_name = "authentication_lambda"
  role          = var.aws_iam_role
  handler       = "index.handler"
  runtime       = "python3.9"

  # Código da função Lambda (implantado a partir de um arquivo .zip)
  filename         = "authentication_lambda.zip"
  source_code_hash = filebase64sha256("authentication_lambda.zip")

  # Ambiente de execução da Lambda
  environment {
    variables = {
       DATABASE_URL = "postgresql://${data.terraform_remote_state.banco_de_dados.outputs.db_username}:${var.db_password}@${data.terraform_remote_state.banco_de_dados.outputs.db_endpoint}:${data.terraform_remote_state.banco_de_dados.outputs.db_port}/${data.terraform_remote_state.banco_de_dados.outputs.db_name}"
    }
  }

  # Políticas de permissão para a Lambda
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess"
  ]
}

# API Gateway
resource "aws_api_gateway_rest_api" "authentication_api" {
  name        = "authentication_api"
  description = "API para autenticação de usuário"
}

# Recurso do API Gateway para a rota de autenticação
resource "aws_api_gateway_resource" "authentication_resource" {
  rest_api_id = aws_api_gateway_rest_api.authentication_api.id
  parent_id   = aws_api_gateway_rest_api.authentication_api.root_resource_id
  path_part   = "authenticate"
}

# Método do API Gateway (POST)
resource "aws_api_gateway_method" "authentication_method" {
  rest_api_id   = aws_api_gateway_rest_api.authentication_api.id
  resource_id   = aws_api_gateway_resource.authentication_resource.id
  http_method   = "POST"
  authorization = "NONE" 
}

# Integração da Lambda com o API Gateway
resource "aws_api_gateway_integration" "authentication_integration" {
  rest_api_id = aws_api_gateway_rest_api.authentication_api.id
  resource_id = aws_api_gateway_resource.authentication_resource.id
  http_method = aws_api_gateway_method.authentication_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.authentication_lambda.invoke_arn
}

# Deploy do API Gateway
resource "aws_api_gateway_deployment" "authentication_deployment" {
  depends_on = [
    aws_api_gateway_integration.authentication_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.authentication_api.id
  stage_name  = "prod" 
}

# Cognito User Pool (configuração básica)
resource "aws_cognito_user_pool" "user_pool" {
  name = "meu_user_pool"
}

# Cognito User Pool Client (configuração básica)
resource "aws_cognito_user_pool_client" "client" {
  name         = "meu_app_client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}
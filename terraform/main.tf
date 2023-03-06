terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# data "aws_ssm_parameter" "foo" {
#   name = "foo"
# }

resource "aws_lambda_function" "vassopolibot_telegram_adapter" {
  filename      = "main.zip"
  function_name = "vassopolibot-telegram-adapter"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ExecuteVassopoliBotTelegramAdapter"
  handler       = "main"
  runtime       = "go1.x"
}

resource "aws_cloudwatch_log_group" "vassopolibot_telegram_adapter" {
  name = "/aws/lambda/${aws_lambda_function.vassopolibot_telegram_adapter.function_name}"
  retention_in_days = 14
}

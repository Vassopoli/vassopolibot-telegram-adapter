terraform {
  cloud {
    organization = "vassopoli"

    workspaces {
      name = "test-workspace"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.38.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "app_telegram_token" {
  type      = string
  sensitive = true
}

data "aws_caller_identity" "current" {}

# data "aws_ssm_parameter" "foo" {
#   name = "foo"
# }

resource "aws_sqs_queue" "vassopolibot_telegram_adapter_queue" {
  name                      = "VassopoliBotTelegramAdapterQueue"
}

resource "aws_lambda_function" "vassopolibot_telegram_adapter" {
  filename      = "main.zip"
  function_name = "vassopolibot-telegram-adapter"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ExecuteVassopoliBotTelegramAdapter"
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  source_code_hash = "${base64sha256("main.zip")}"
  
  environment {
    variables = {
      APP_TELEGRAM_TOKEN = var.app_telegram_token
    }
  }
}

resource "aws_cloudwatch_log_group" "vassopolibot_telegram_adapter" {
  name = "/aws/lambda/${aws_lambda_function.vassopolibot_telegram_adapter.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_event_source_mapping" "queue_to_lambda" {
  event_source_arn = aws_sqs_queue.vassopolibot_telegram_adapter_queue.arn
  function_name    = aws_lambda_function.vassopolibot_telegram_adapter.arn
}

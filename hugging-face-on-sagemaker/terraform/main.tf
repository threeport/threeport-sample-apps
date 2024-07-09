terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_iam_policy_document" "distilbert_policy" {
  statement {
    sid = "SageMakerAccess"
    effect = "Allow"
    principals {
        type = "Service"
        identifiers = ["sagemaker.amazonaws.com"]
    }
    principals {
        type = "AWS"
        identifiers = [var.principal]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "distilbert_sagemaker_role" {
  name = "distilbert_sagemaker_role"
  tags = {
    App = "distilbert"
    Tier = "test"
  }
  assume_role_policy = data.aws_iam_policy_document.distilbert_policy.json
}

resource "aws_iam_role_policy_attachment" "distilbert_sagemaker_attachment" {
  role       = aws_iam_role.distilbert_sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}


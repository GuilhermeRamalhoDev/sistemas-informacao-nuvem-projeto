terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
  # State LOCAL de propósito: isto cria o backend remoto que o resto do
  # projeto usa, por isso não pode depender dele (problema do ovo e da galinha).
}

provider "aws" {
  region = var.aws_region
}

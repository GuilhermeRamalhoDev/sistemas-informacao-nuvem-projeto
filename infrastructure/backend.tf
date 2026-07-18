# Remote state em S3 com locking via DynamoDB.
# O bucket e a tabela têm de existir ANTES do primeiro `terraform init`
# (ver docs/setup.md — secção "Bootstrap do backend").
terraform {
  backend "s3" {
    bucket         = "sinuvem-eventos-tfstate-994655851630"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sinuvem-eventos-tflocks"
    encrypt        = true
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  description = "Nome do bucket S3 para o remote state (deve ser globalmente único)"
  type        = string
  default     = "sinuvem-eventos-tfstate-994655851630"
}

variable "lock_table_name" {
  description = "Nome da tabela DynamoDB para locking do state"
  type        = string
  default     = "sinuvem-eventos-tflocks"
}

variable "github_repo" {
  description = "Repositório GitHub no formato owner/repo (ex: guilh/sinuvem-eventos)"
  type        = string
}

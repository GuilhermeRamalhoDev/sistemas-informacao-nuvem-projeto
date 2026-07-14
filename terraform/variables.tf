variable "aws_region" {
  description = "Região AWS onde a infraestrutura é criada"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo usado nos nomes e tags dos recursos"
  type        = string
  default     = "sinuvem-eventos"
}

variable "environment" {
  description = "Ambiente (dev/prod)"
  type        = string
  default     = "dev"
}

variable "db_username" {
  description = "Utilizador administrador da base de dados RDS"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Password da base de dados RDS (injetada por GitHub Secret, nunca hardcoded)"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Nome do EC2 Key Pair já existente na conta (para acesso SSH do Ansible)"
  type        = string
}

variable "ssh_ingress_cidr" {
  description = "CIDR autorizado a aceder por SSH (porta 22). Restringe ao teu IP em vez de 0.0.0.0/0"
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Porta exposta pela API"
  type        = number
  default     = 8000
}

variable "project_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "db_sg_id" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "eventsdb"
}

variable "multi_az" {
  description = "Ativa RDS Multi-AZ (standby síncrono + failover automático)"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Dias de retenção de backups automáticos (necessário >0 para read replicas)"
  type        = number
  default     = 7
}

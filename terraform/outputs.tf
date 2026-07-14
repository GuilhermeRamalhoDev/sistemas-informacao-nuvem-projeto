output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.networking.vpc_id
}

output "ec2_public_ip" {
  description = "IP público da EC2 (acesso à API e SSH do Ansible)"
  value       = module.compute.public_ip
}

output "rds_endpoint" {
  description = "Endpoint da base de dados RDS"
  value       = module.database.endpoint
}

output "rds_database_url" {
  description = "DATABASE_URL completo para a aplicação (sensível: contém password)"
  value       = "postgresql+psycopg2://${var.db_username}:${var.db_password}@${module.database.endpoint}/${module.database.db_name}"
  sensitive   = true
}

output "queue_url" {
  description = "URL da fila SQS principal"
  value       = module.queue.queue_url
}

output "dlq_url" {
  description = "URL da Dead Letter Queue"
  value       = module.queue.dlq_url
}

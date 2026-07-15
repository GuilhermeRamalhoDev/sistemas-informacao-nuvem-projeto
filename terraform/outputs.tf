# --- Ponto de entrada único (failover automático) ---
output "accelerator_ip" {
  description = "IP estático do Global Accelerator — usar este para aceder à app"
  value       = module.accelerator.static_ip
}

output "accelerator_dns" {
  value = module.accelerator.dns_name
}

# --- Primário (us-east-1) — configurado pelo Ansible ---
output "ec2_public_ip" {
  description = "IP público da EC2 primária (acesso SSH do Ansible)"
  value       = module.primary.ec2_public_ip
}

output "web_sg_id" {
  description = "Security Group da EC2 primária (o CI abre/fecha SSH aqui)"
  value       = module.primary.web_sg_id
}

output "primary_instance_id" {
  description = "ID da EC2 primária (usado pelo failover drill)"
  value       = module.primary.ec2_instance_id
}

output "queue_url" {
  description = "URL da fila SQS do primário"
  value       = module.primary.queue_url
}

output "rds_database_url" {
  description = "DATABASE_URL do primário (sensível: contém password)"
  value       = "postgresql+psycopg2://${var.db_username}:${var.db_password}@${module.primary.rds_endpoint}/${module.primary.db_name}"
  sensitive   = true
}

# --- Standby (us-west-2) — auto-provisionado ---
output "standby_ec2_public_ip" {
  description = "IP público da EC2 standby"
  value       = module.standby.ec2_public_ip
}

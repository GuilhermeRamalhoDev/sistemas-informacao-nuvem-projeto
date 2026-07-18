# --- Failover automático (Route 53) ---
output "dns_zone_id" {
  description = "ID da hosted zone de failover (usado pelo drill)"
  value       = module.dns.zone_id
}

output "dns_record_fqdn" {
  description = "FQDN da app com failover (consultar via nameservers da zona)"
  value       = module.dns.record_fqdn
}

output "dns_name_servers" {
  description = "Nameservers da zona (demo: dig @<ns> <fqdn>)"
  value       = module.dns.name_servers
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

# A password NÃO é exposta em outputs: a EC2 primária vai buscá-la ao SSM
# (tal como a standby). Aqui expomos apenas os dados não sensíveis.
output "primary_rds_endpoint" {
  description = "Endpoint do RDS primário"
  value       = module.primary.rds_endpoint
}

output "primary_db_name" {
  description = "Nome da base de dados do primário"
  value       = module.primary.db_name
}

output "primary_ssm_param_name" {
  description = "Parâmetro SSM com a password do primário"
  value       = module.primary.ssm_param_name
}

output "db_username" {
  description = "Utilizador da base de dados"
  value       = var.db_username
}

# --- Standby (us-west-2) — auto-provisionado ---
output "standby_ec2_public_ip" {
  description = "IP público da EC2 standby"
  value       = module.standby.ec2_public_ip
}

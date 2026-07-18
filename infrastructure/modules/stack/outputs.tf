output "ec2_public_ip" {
  value = module.compute.public_ip
}

output "ec2_instance_id" {
  value = module.compute.instance_id
}

output "web_sg_id" {
  value = module.networking.web_sg_id
}

output "queue_url" {
  value = module.queue.queue_url
}

output "rds_endpoint" {
  value = module.database.endpoint
}

output "db_name" {
  value = module.database.db_name
}

output "ssm_param_name" {
  description = "Nome do parâmetro SSM com a password (lido pela EC2 via Instance Profile)"
  value       = aws_ssm_parameter.db_password.name
}

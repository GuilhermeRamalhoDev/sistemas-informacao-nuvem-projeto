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

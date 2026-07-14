output "endpoint" {
  # Sem a porta — formato host:port é devolvido por .endpoint; usamos .address.
  value = aws_db_instance.db.address
}

output "db_name" {
  value = aws_db_instance.db.db_name
}

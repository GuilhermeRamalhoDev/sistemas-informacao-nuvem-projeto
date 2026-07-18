resource "aws_db_subnet_group" "db" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "db" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [var.db_sg_id]

  publicly_accessible = false
  skip_final_snapshot = true

  # --- Resiliência de dados (Disaster Recovery) ---
  # Multi-AZ: a AWS mantém um standby síncrono noutra AZ e faz failover
  # automático da base de dados (RPO ~0). Permite também criar read replicas
  # cross-region a partir dos backups automáticos.
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period

  tags = { Name = "${var.project_name}-rds" }
}

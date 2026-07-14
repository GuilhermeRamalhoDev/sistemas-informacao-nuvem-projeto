provider "aws" {
  region = var.aws_region

  # Tags aplicadas automaticamente a todos os recursos (consistência e rastreio de custos).
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ---------------------------------------------------------------------------
# Rede: VPC, subnets públicas/privadas, IGW, route tables, security groups.
# ---------------------------------------------------------------------------
module "networking" {
  source           = "./modules/networking"
  project_name     = var.project_name
  ssh_ingress_cidr = var.ssh_ingress_cidr
  app_port         = var.app_port
}

# ---------------------------------------------------------------------------
# Filas: SQS principal + Dead Letter Queue.
# ---------------------------------------------------------------------------
module "queue" {
  source       = "./modules/queue"
  project_name = var.project_name
}

# ---------------------------------------------------------------------------
# IAM: role + instance profile para a EC2 com permissão SQS *scoped*
# (apenas as filas deste projeto). Evita credenciais hardcoded no código.
# ---------------------------------------------------------------------------
module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  queue_arn    = module.queue.queue_arn
  dlq_arn      = module.queue.dlq_arn
}

# ---------------------------------------------------------------------------
# Base de dados: RDS PostgreSQL em subnets privadas.
# ---------------------------------------------------------------------------
module "database" {
  source             = "./modules/database"
  project_name       = var.project_name
  private_subnet_ids = module.networking.private_subnet_ids
  db_sg_id           = module.networking.db_sg_id
  db_username        = var.db_username
  db_password        = var.db_password
}

# ---------------------------------------------------------------------------
# Compute: instância EC2 que corre os containers (API + Worker).
# ---------------------------------------------------------------------------
module "compute" {
  source           = "./modules/compute"
  project_name     = var.project_name
  public_subnet_id = module.networking.public_subnet_ids[0]
  web_sg_id        = module.networking.web_sg_id
  instance_profile = module.iam.instance_profile_name
  key_name         = var.key_name
}

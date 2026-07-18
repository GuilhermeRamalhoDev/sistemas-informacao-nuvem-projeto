locals {
  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Provider da região PRIMÁRIA (us-east-1).
provider "aws" {
  region = var.aws_region
  default_tags { tags = local.default_tags }
}

# Provider da região STANDBY (us-west-2). Também usado para o Global Accelerator
# (que só pode ser gerido em us-west-2).
provider "aws" {
  alias  = "standby"
  region = var.standby_region
  default_tags { tags = local.default_tags }
}

# ---------------------------------------------------------------------------
# PRIMÁRIO — configurado pelo Ansible (pipeline).
# NOTA: multi_az=false porque a conta é Free Tier (Multi-AZ não incluído).
# A resiliência de dados é garantida por snapshots automáticos (ver docs/dr.md).
# ---------------------------------------------------------------------------
module "primary" {
  source           = "./modules/stack"
  name_prefix      = "${var.project_name}-primary"
  region           = var.aws_region
  ssh_ingress_cidr = var.ssh_ingress_cidr
  app_port         = var.app_port
  key_name         = var.key_name
  db_username      = var.db_username
  db_password      = var.db_password
  multi_az         = false
}

# ---------------------------------------------------------------------------
# STANDBY — auto-provisionado por user_data (sem SSH). RDS single-AZ.
# É uma instância parametrizada da MESMA stack, noutra região.
# ---------------------------------------------------------------------------
module "standby" {
  source                = "./modules/stack"
  providers             = { aws = aws.standby }
  name_prefix           = "${var.project_name}-standby"
  region                = var.standby_region
  ssh_ingress_cidr      = var.ssh_ingress_cidr
  app_port              = var.app_port
  db_username           = var.db_username
  db_password           = var.db_password
  multi_az              = false
  enable_self_provision = true
  image_base            = var.image_base
  image_tag             = var.image_tag
}

# ---------------------------------------------------------------------------
# Route 53 — failover automático primário -> standby por health checks.
# (Alternativa ao Global Accelerator, que não está disponível no Free Tier.)
# ---------------------------------------------------------------------------
module "dns" {
  source     = "./modules/dns"
  app_port   = var.app_port
  primary_ip = module.primary.ec2_public_ip
  standby_ip = module.standby.ec2_public_ip
}

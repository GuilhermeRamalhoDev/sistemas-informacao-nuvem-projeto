# Stack = infraestrutura completa de UMA região (app tier + dados + filas).
# É instanciado duas vezes a partir do root: primário (us-east-1) e standby
# (us-west-2). O standby é uma cópia parametrizada do primário.

module "networking" {
  source           = "../networking"
  project_name     = var.name_prefix
  ssh_ingress_cidr = var.ssh_ingress_cidr
  app_port         = var.app_port
}

module "queue" {
  source       = "../queue"
  project_name = var.name_prefix
}

# Password da BD guardada no SSM Parameter Store (SecureString), não hardcoded.
# O standby vai buscá-la aqui no arranque (user_data), via Instance Profile.
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.name_prefix}/db_password"
  type  = "SecureString"
  value = var.db_password
}

module "iam" {
  source            = "../iam"
  project_name      = var.name_prefix
  queue_arn         = module.queue.queue_arn
  dlq_arn           = module.queue.dlq_arn
  ssm_parameter_arn = aws_ssm_parameter.db_password.arn
}

module "database" {
  source             = "../database"
  project_name       = var.name_prefix
  private_subnet_ids = module.networking.private_subnet_ids
  db_sg_id           = module.networking.db_sg_id
  db_username        = var.db_username
  db_password        = var.db_password
  multi_az           = var.multi_az
}

# O standby auto-configura-se por user_data (busca a password ao SSM e arranca
# os containers). O primário deixa user_data a null e é configurado pelo Ansible.
locals {
  standby_user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    name_prefix  = var.name_prefix
    region       = var.region
    db_username  = var.db_username
    rds_endpoint = module.database.endpoint
    db_name      = module.database.db_name
    queue_url    = module.queue.queue_url
    image_base   = var.image_base
    image_tag    = var.image_tag
  })
}

module "compute" {
  source           = "../compute"
  project_name     = var.name_prefix
  public_subnet_id = module.networking.public_subnet_ids[0]
  web_sg_id        = module.networking.web_sg_id
  instance_profile = module.iam.instance_profile_name
  key_name         = var.key_name
  user_data        = var.enable_self_provision ? local.standby_user_data : null
}

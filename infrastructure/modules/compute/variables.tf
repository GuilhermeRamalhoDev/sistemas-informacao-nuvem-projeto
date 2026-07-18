variable "project_name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "web_sg_id" {
  type = string
}

variable "instance_profile" {
  description = "Nome do IAM Instance Profile a associar à EC2"
  type        = string
}

variable "key_name" {
  description = "Nome do EC2 Key Pair existente (null se não houver acesso SSH, ex: standby)"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Script de arranque (cloud-init). Usado no standby para auto-configuração sem SSH."
  type        = string
  default     = null
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

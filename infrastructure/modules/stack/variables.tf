variable "name_prefix" {
  description = "Prefixo único dos recursos desta região (ex: sinuvem-eventos-primary)"
  type        = string
}

variable "ssh_ingress_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "app_port" {
  type    = number
  default = 8000
}

variable "key_name" {
  description = "EC2 Key Pair (null no standby, que usa user_data)"
  type        = string
  default     = null
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "multi_az" {
  description = "RDS Multi-AZ (true no primário)"
  type        = bool
  default     = false
}

variable "region" {
  description = "Região desta stack (usada no user_data e nas env vars)"
  type        = string
}

variable "enable_self_provision" {
  description = "Se true, a EC2 auto-configura-se via user_data (standby). Se false, é o Ansible que a configura (primário)."
  type        = bool
  default     = false
}

variable "image_base" {
  description = "Base das imagens GHCR (ex: ghcr.io/owner/repo)"
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "Tag das imagens a usar no standby"
  type        = string
  default     = "latest"
}

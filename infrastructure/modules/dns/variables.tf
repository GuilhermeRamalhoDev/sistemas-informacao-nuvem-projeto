variable "zone_name" {
  description = "Nome da hosted zone (placeholder; consultada diretamente na demo)"
  type        = string
  default     = "sinuvem-eventos.dr"
}

variable "record_name" {
  description = "Nome do registo da aplicação"
  type        = string
  default     = "app"
}

variable "app_port" {
  type = number
}

variable "primary_ip" {
  type = string
}

variable "standby_ip" {
  type = string
}

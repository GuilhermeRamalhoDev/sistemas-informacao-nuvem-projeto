variable "name" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8000
}

variable "primary_region" {
  type = string
}

variable "primary_instance_id" {
  type = string
}

variable "standby_region" {
  type = string
}

variable "standby_instance_id" {
  type = string
}

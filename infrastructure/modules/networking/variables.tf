variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ssh_ingress_cidr" {
  type = string
}

variable "app_port" {
  type = number
}

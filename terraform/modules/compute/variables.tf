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
  description = "Nome do EC2 Key Pair existente"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

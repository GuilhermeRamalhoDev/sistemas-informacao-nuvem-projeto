variable "project_name" {
  type = string
}

variable "queue_arn" {
  description = "ARN da fila SQS principal"
  type        = string
}

variable "dlq_arn" {
  description = "ARN da Dead Letter Queue"
  type        = string
}

variable "ssm_parameter_arn" {
  description = "ARN do parâmetro SSM com a password da BD"
  type        = string
}

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

output "state_bucket" {
  value = aws_s3_bucket.state.id
}

output "lock_table" {
  value = aws_dynamodb_table.locks.name
}

output "github_actions_role_arn" {
  description = "Copia para o GitHub Secret AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

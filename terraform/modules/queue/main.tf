resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-dlq"
}

resource "aws_sqs_queue" "main" {
  name = "${var.project_name}-queue"

  # Mensagens que falham 3 vezes são movidas para a DLQ.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

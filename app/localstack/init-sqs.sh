#!/bin/bash
# Executado automaticamente pelo LocalStack quando fica pronto.
# Cria a fila principal e a Dead Letter Queue (DLQ), ligando-as por redrive policy.
set -e

awslocal sqs create-queue --queue-name event-dlq

DLQ_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url http://localhost:4566/000000000000/event-dlq \
  --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

awslocal sqs create-queue --queue-name event-queue \
  --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}"

echo "Filas SQS criadas: event-queue + event-dlq"

# Role que a EC2 assume. Permite que a aplicação use a SQS SEM credenciais
# hardcoded: o boto3 obtém credenciais temporárias via instance metadata.

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Política de menor privilégio: apenas as ações SQS necessárias,
# e apenas sobre as filas DESTE projeto (queue + dlq).
data "aws_iam_policy_document" "sqs_access" {
  statement {
    sid    = "AllowSqsOnProjectQueues"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [
      var.queue_arn,
      var.dlq_arn,
    ]
  }
}

resource "aws_iam_role_policy" "sqs_access" {
  name   = "${var.project_name}-sqs-access"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.sqs_access.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

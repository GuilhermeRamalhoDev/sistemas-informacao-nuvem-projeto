data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.web_sg_id]
  iam_instance_profile   = var.instance_profile
  key_name               = var.key_name
  user_data              = var.user_data

  # IMDSv2 obrigatório. hop_limit=2 permite que os containers Docker acedam
  # às credenciais do Instance Profile (o bridge do Docker conta como 1 salto).
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = { Name = "${var.project_name}-app-ec2" }
}

# Elastic IP: IP público estável (não muda em stop/start), necessário para os
# health checks do Route 53 e para o failover drill.
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-eip" }
}

# AWS Global Accelerator: um IP estático único com failover AUTOMÁTICO por
# health checks entre a região primária e a standby. Sem domínio, sem consola.
#
# NOTA: os recursos de Global Accelerator só podem ser geridos na região
# us-west-2 — o root passa o provider adequado a este módulo.

resource "aws_globalaccelerator_accelerator" "main" {
  name            = var.name
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "app" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  protocol        = "TCP"

  port_range {
    from_port = var.app_port
    to_port   = var.app_port
  }
}

# Grupo de endpoints do PRIMÁRIO (região preferida por proximidade).
resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn          = aws_globalaccelerator_listener.app.id
  endpoint_group_region = var.primary_region

  health_check_protocol         = "HTTP"
  health_check_path             = "/health"
  health_check_port             = var.app_port
  health_check_interval_seconds = 10
  threshold_count               = 2

  endpoint_configuration {
    endpoint_id                    = var.primary_instance_id
    weight                         = 128
    client_ip_preservation_enabled = false
  }
}

# Grupo de endpoints do STANDBY (assume o tráfego se o primário ficar unhealthy).
resource "aws_globalaccelerator_endpoint_group" "standby" {
  listener_arn          = aws_globalaccelerator_listener.app.id
  endpoint_group_region = var.standby_region

  health_check_protocol         = "HTTP"
  health_check_path             = "/health"
  health_check_port             = var.app_port
  health_check_interval_seconds = 10
  threshold_count               = 2

  endpoint_configuration {
    endpoint_id                    = var.standby_instance_id
    weight                         = 128
    client_ip_preservation_enabled = false
  }
}

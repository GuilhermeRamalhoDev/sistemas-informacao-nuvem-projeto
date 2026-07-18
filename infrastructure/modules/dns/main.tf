# Failover automático por DNS com Route 53 (compatível com Free Tier, sem
# domínio pago). Um health check monitoriza o primário; se falhar, o Route 53
# passa a responder com o IP do standby — sem qualquer intervenção manual.

resource "aws_route53_zone" "dr" {
  name = var.zone_name
}

# Health check HTTP ao /health do primário (via Elastic IP estável).
resource "aws_route53_health_check" "primary" {
  ip_address        = var.primary_ip
  port              = var.app_port
  type              = "HTTP"
  resource_path     = "/health"
  request_interval  = 10
  failure_threshold = 2

  tags = { Name = "primary-health" }
}

# Registo PRIMARY: responde com o IP do primário enquanto estiver saudável.
resource "aws_route53_record" "primary" {
  zone_id        = aws_route53_zone.dr.zone_id
  name           = var.record_name
  type           = "A"
  ttl            = 10
  set_identifier = "primary"
  records        = [var.primary_ip]

  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.primary.id
}

# Registo SECONDARY: assume quando o primário fica unhealthy.
resource "aws_route53_record" "standby" {
  zone_id        = aws_route53_zone.dr.zone_id
  name           = var.record_name
  type           = "A"
  ttl            = 10
  set_identifier = "standby"
  records        = [var.standby_ip]

  failover_routing_policy {
    type = "SECONDARY"
  }
}

output "zone_id" {
  value = aws_route53_zone.dr.zone_id
}

output "record_fqdn" {
  value = "${var.record_name}.${var.zone_name}"
}

output "name_servers" {
  description = "Nameservers da zona (para consulta direta na demo: dig @<ns> <fqdn>)"
  value       = aws_route53_zone.dr.name_servers
}

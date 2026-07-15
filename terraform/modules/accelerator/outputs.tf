output "static_ip" {
  description = "IP estático do Global Accelerator (ponto de entrada único)"
  value       = tolist(aws_globalaccelerator_accelerator.main.ip_sets[0].ip_addresses)[0]
}

output "dns_name" {
  value = aws_globalaccelerator_accelerator.main.dns_name
}

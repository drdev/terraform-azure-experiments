output "environment" {
  value = var.environment
}

output "public-ip" {
  value = azurerm_public_ip.main.ip_address
}

output "verify" {
  value = "while true; do curl -s http://${azurerm_public_ip.main.ip_address}; sleep 5; done"
  description = "Run this one-liner to check load balancing."
}

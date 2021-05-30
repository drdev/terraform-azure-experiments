output "application-environment" {
  value = var.application-environment
}

output "public-ip" {
  value = azurerm_public_ip.main.ip_address
}
output "dc01_public_ip" {
  description = "DC01 public IP - used for RDP and Lab 2 configuration"
  value       = azurerm_public_ip.dc01.ip_address
}

output "fs01_public_ip" {
  description = "FS01 public IP - used for RDP and Lab 3 configuration"
  value       = azurerm_public_ip.fs01.ip_address
}

output "client01_public_ip" {
  description = "CLIENT01 public IP - used for RDP access testing in Lab 3"
  value       = azurerm_public_ip.client01.ip_address
}

output "dc01_private_ip" {
  description = "DC01 private IP - DNS server for the lab domain"
  value       = "10.0.1.5"
}

output "resource_group_name" {
  description = "Resource group name - referenced by Lab 2 and Lab 3"
  value       = azurerm_resource_group.rg.name
}

output "key_vault_name" {
  description = "Key Vault name storing the VM admin password"
  value       = azurerm_key_vault.lab_kv.name
}

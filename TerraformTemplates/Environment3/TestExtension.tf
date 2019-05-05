resource "azurerm_virtual_machine_extension" "test" {
  name                 = "hostname"
  location             = "Central US"
  resource_group_name  = "DCB-ENV3-RG-001"
  virtual_machine_name = "env3-vm-001"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "hostname && uptime;ping 10.100.50.5  -c 3 "
    }
SETTINGS
  tags = {
    environment = "Production"
  }
}
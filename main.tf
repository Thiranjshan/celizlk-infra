# main.tf
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "celizvm" {
  name                = "celizvm-ip"
  resource_group_name = azurerm_resource_group.main.name
  location             = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "celizvm" {
  name                = "celizvm-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "SSH"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.celizvm.name
}

resource "azurerm_network_security_rule" "https" {
  name                        = "HTTPS"
  priority                    = 320
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.celizvm.name
}

resource "azurerm_network_security_rule" "http" {
  name                        = "HTTP"
  priority                    = 340
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.celizvm.name
}

resource "azurerm_ssh_public_key" "celiz_key" {
  name                = "celiz_key"
  resource_group_name = "CELIZ_GROUP"
  location            = var.location
  public_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDowONZafRMVk0NHyxFYTEow5OSRP7CRTFy6lS933EWPnx9pg0agpWUwFJlS/HMUzYJIt1FlQvKBkwPly3auI87WQTH26pXwDr996A6N8oEeTWYac/OVkPgfHnTAGrPPfSDT6/qLrFyV47uTQW2nQFZd7WLC0VrGTj/xML0xbdC33hX4IvgMNnez1VeIxNrkLFMht8BsveIPjj3uKmo8FaSRL74dC3OgOLYa/DFU5DtR9W6wzSTkF7oaJFaJE14YIb6Nx/u5DeCA2nqqH54TDaWx3VI09Lpl1D5BGvS/DXZegVH0bbOeJ0mZ1q1OY2Jr9C61s/u4Jm2IZlvkBwYkd3ADc6fpuV1uHe3BJygAPfPGnpr2jXDI55WyXqVfXiSWYg/5/qFh3CoDvuICfojBBnt18dG3VB1KTbxoXcwPSm4d9/ibRrzm2nBOTsM+YxBBV0leyt05gbUnuJuuoO2N5Q3NSoTgnEiKFCMIcqajtz2ylSEKQF+Ji9Vo9yfKUDDyE= generated-by-azure"
}

resource "azurerm_virtual_network" "celizvm" {
  name                = "celizvm-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.1.0.0/16"]
}
resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.celizvm.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_network_interface" "celizvm" {
  name                = "celizvm675"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.celizvm.id
  }

  accelerated_networking_enabled = false
  ip_forwarding_enabled          = false
}

resource "azurerm_network_interface_security_group_association" "celizvm" {
  network_interface_id      = azurerm_network_interface.celizvm.id
  network_security_group_id = azurerm_network_security_group.celizvm.id
}

resource "azurerm_managed_disk" "celizvm_os" {
  name                 = "celizvm_disk1_05e193e83896440ebf61e5d6c0d232e1"
  location             = var.location
  resource_group_name  = "CELIZ_GROUP"
  storage_account_type = "Premium_LRS"
  create_option        = "FromImage"
  disk_size_gb         = 64
  hyper_v_generation   = "V2"
  os_type              = "Linux"

  image_reference_id = "/Subscriptions/a189363f-28b0-4a18-a7bb-03f1593e50cf/Providers/Microsoft.Compute/Locations/CentralIndia/Publishers/canonical/ArtifactTypes/VMImage/Offers/ubuntu-22_04-lts/Skus/server/Versions/22.04.202609040"

  on_demand_bursting_enabled = false
  trusted_launch_enabled     = false
}

resource "azurerm_linux_virtual_machine" "celizvm" {
  name                = "celizvm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B2ats_v2"
  admin_username      = "azureuser"

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.celizvm.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_ssh_public_key.celiz_key.public_key
  }

  os_disk {
    name                 = azurerm_managed_disk.celizvm_os.name
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-22_04-lts"
    sku       = "server"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "azure_monitor_linux_agent" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.celizvm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}

resource "azurerm_monitor_action_group" "celizvm" {
  name                = "VMI-ActionGroup-celizvm"
  resource_group_name = var.resource_group_name
  short_name          = "VMI-celizvm"
  enabled             = true

  email_receiver {
    name                    = "Email-thiranjayaishan@Gmail.com"
    email_address           = "thiranjayaishan@Gmail.com"
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_data_collection_rule" "celizvm" {
  name                = "msvmi-centralindia-celizvm"
  resource_group_name = var.resource_group_name
  location            = var.location

  destinations {
    monitor_account {
      name               = "MonitoringAccountDestination"
      monitor_account_id = "/subscriptions/c6b24dd6-a326-4336-8d37-ffeb5ddcd5df/resourcegroups/defaultresourcegroup-cid/providers/microsoft.monitor/accounts/defaultazuremonitorworkspace-cid"
    }
  }

  data_sources {}

  data_flow {
    streams      = ["Microsoft-OtelPerfMetrics"]
    destinations = ["MonitoringAccountDestination"]
  }
}

resource "azurerm_postgresql_flexible_server" "celiz_pg" {
  name                          = "celiz-pg"
  resource_group_name           = var.resource_group_name
  location                      = "indiasouthcentral"
  administrator_password = var.pg_admin_password
  version                       = "18"
  administrator_login           = "celizpgadmin"
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  storage_tier                  = "P4"
  zone                          = "1"
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  auto_grow_enabled             = false
  public_network_access_enabled = true

  authentication {
    active_directory_auth_enabled = false
    password_auth_enabled         = true
  }

}

resource "azurerm_postgresql_flexible_server_firewall_rule" "client_ip" {
  name             = "ClientIPAddress_2026-9-20_19-10-25"
  server_id        = azurerm_postgresql_flexible_server.celiz_pg.id
  start_ip_address = "223.224.30.96"
  end_ip_address   = "223.224.30.96"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "vm_public" {
  name             = "VMPublic"
  server_id        = azurerm_postgresql_flexible_server.celiz_pg.id
  start_ip_address = "20.198.0.247"
  end_ip_address   = "20.198.0.247"
}
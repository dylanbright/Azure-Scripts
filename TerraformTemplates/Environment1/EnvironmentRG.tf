terraform {
  backend "azurerm" {
    storage_account_name  = "tstate28063"
    container_name        = "tstate"
    key                   = "environment1.terraform.tfstate"
    access_key            = "ak/bbi75rKWxsuIiaXhRspyMYATKxz2sZDIa6kOwR+6uLS8yR25wqMyL15NI2CJ9ZvIAvNleASbqCVhHNq1jMQ=="
    #sas_token             = "?sv=2018-03-28&ss=bfqt&srt=sco&sp=rwdlacup&se=2025-05-04T19:54:19Z&st=2019-05-04T11:54:19Z&spr=https&sig=CirWD59UBpD0bsPiG0r7GIj1N5eH9E9Ev97iq6vDsps%3D"
  }
}

provider "azurerm" {
    subscription_id = "11541666-34de-4eaa-84a2-801039426abf"
    client_id       = "90fffc8e-74a0-44ac-bd2c-c5e3347a270a"
    client_secret   = "wpkA+Ku28fFUixFByr9V9oxK2SefPNDr0v3qkQj+H6g="
    tenant_id       = "7ebade21-0159-4dd6-9c45-bb96bcfbce96"
}

resource "azurerm_resource_group" "DCB-ENV1-RG-001" {
  name     = "DCB-ENV1-RG-001"
  location = "Central US"

  tags = {
    environment = "Prod"
  }
}


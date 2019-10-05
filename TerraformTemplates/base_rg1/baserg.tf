#variables
variable "rgname" {

}

variable "rglocation" {

}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "11541666-34de-4eaa-84a2-801039426abf"
    client_id       = "90fffc8e-74a0-44ac-bd2c-c5e3347a270a"
    client_secret   = "wpkA+Ku28fFUixFByr9V9oxK2SefPNDr0v3qkQj+H6g="
    tenant_id       = "7ebade21-0159-4dd6-9c45-bb96bcfbce96"
}

#create the base resource group
resource "azurerm_resource_group" "mybaserg" {
    name     = "${var.rgnam}"
    location = "${var.rglocation}"

    tags {
        environment = "dcb-base-rg-001"
    }
}
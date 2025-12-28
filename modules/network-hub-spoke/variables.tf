
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "hub_vnet_cidr" { type = string }

variable "hub_subnets" {
  type = map(string)
}

variable "spoke_vnets" {
  type = map(object({
    cidr    = string
    subnets = map(string)
  }))
}


variable "location" {
  type        = string
  description = "Primary Azure region (e.g., eastus)"
  default     = "eastus"
}

variable "org_prefix" {
  type        = string
  description = "Short org prefix used in naming"
  default     = "mbtg"
}

variable "mgmt_group_names" {
  type = object({
    corp           = string
    production     = string
    nonproduction  = string
    sharedservices = string
  })
  default = {
    corp           = "Corp"
    production     = "Production"
    nonproduction  = "Non-Production"
    sharedservices = "Shared-Services"
  }
}

variable "subscription_ids" {
  type = object({
    production     = string
    nonproduction  = string
    sharedservices = string
  })
  description = "Existing subscription IDs to be placed into management groups"
}

variable "tags" {
  type        = map(string)
  description = "Baseline tags applied to resources"
  default = {
    Owner       = "MB Technology Group"
    ManagedBy   = "Terraform"
    Environment = "Shared"
    CostCenter  = "0000"
  }
}

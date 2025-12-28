
variable "mgmt_group_names" {
  type = object({
    corp           = string
    production     = string
    nonproduction  = string
    sharedservices = string
  })
}

variable "subscription_ids" {
  type = object({
    production     = string
    nonproduction  = string
    sharedservices = string
  })
}

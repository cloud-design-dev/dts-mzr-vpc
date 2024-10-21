variable "region" {
  description = "The IBM Cloud region where the VPC and related resources will be deployed."
  type        = string
}

variable "project_prefix" {
  description = "Prefix to assign to all deployed resources. If not provided a random string will be generated."
  type        = string
  default     = ""
}

variable "use_public_gateways" {
  description = "Create a public gateway in any of the three zones set to `true`."
  type = object({
    zone-1 = optional(bool)
    zone-2 = optional(bool)
    zone-3 = optional(bool)
  })
  default = {
    zone-1 = true
    zone-2 = false
    zone-3 = false
  }
  validation {
    error_message = "Keys for `use_public_gateways` must be in the order `zone-1`, `zone-2`, `zone-3`."
    condition = (
      (length(var.use_public_gateways) == 1 && keys(var.use_public_gateways)[0] == "zone-1") ||
      (length(var.use_public_gateways) == 2 && keys(var.use_public_gateways)[0] == "zone-1" && keys(var.use_public_gateways)[1] == "zone-2") ||
      (length(var.use_public_gateways) == 3 && keys(var.use_public_gateways)[0] == "zone-1" && keys(var.use_public_gateways)[1] == "zone-2") && keys(var.use_public_gateways)[2] == "zone-3"
    )
  }
}

variable "resource_group_id" {
  description = "The ID of the resource group to use for deployed resources."
  type        = string
}

variable "classic_access" {
  description = "Indicates if the VPC will have Classic Access."
  type        = bool
  default     = false
}

# Work in progress, the logic for manual address prefix generation is not quite there yet
variable "address_prefix" {
  description = "The address prefix to use if address_prefix_management is set to manual. This will be split in to three prefixes, one for each zone."
  type        = string
  default     = "172.16.0.0/16"
}

variable "owner_tag" {
  description = "The owner tag to assign to all resources."
  type        = string
}

variable "use_custom_prefix" {
  description = "Indicates if custom address prefixes will be used."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to assign to all resources."
  type        = list(string)
  default     = []
}
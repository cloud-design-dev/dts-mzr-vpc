variable "region" {
  description = "The region in which resources will be created"
  type        = string
  default     = "ca-tor"
}

variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key"
  type        = string
  sensitive   = true
}

variable "existing_resource_group" {
  description = "Name of an existing Resource Group to use for resources. If not set, a new Resource Group will be created."
  type        = string
  default     = null
}

variable "allow_ssh_from" {
  description = "An IP or CIDR block to allow SSH access from. This will be added to the default VPC security group."
  type        = string
  default     = "0.0.0.0/0"
}

variable "owner" {
  description = "Project owner or identifier. This is used as a tag on all supported resources."
  type        = string
}

variable "classic_access" {
  description = "Allow classic access to the VPC."
  type        = bool
  default     = false
}

variable "default_address_prefix" {
  description = "The address prefix to use for the VPC. Default is set to auto."
  type        = string
  default     = "auto"
}

variable "existing_ssh_key" {
  description = "The name of an existing SSH key to use. If not specified, a new key will be created."
  type        = string
  default     = ""
}

variable "allow_ip_spoofing" {
  description = "Allow IP spoofing on the bastion instance primary interface."
  type        = bool
  default     = false
}

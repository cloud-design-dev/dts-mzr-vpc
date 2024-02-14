variable "region" {
  description = "The region in which resources will be created"
  type        = string
  default     = "us-south"
}

variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key"
  type        = string
  sensitive   = true
}

variable "project_prefix" {
  description = "The prefix to use for all resources in this project"
  type        = string
  default     = ""
}

variable "existing_resource_group" {
  description = "Name of an existing Resource Group to use for resources. If not set, a new Resource Group will be created."
  type        = string
  default     = null
}

variable "allow_ssh_from" {
  description = "An IP or CIDR block to allow SSH access from on the bastion host"
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

variable "instance_profile" {
  description = "The name of an existing instance profile to use. You can list available instance profiles with the command 'ibmcloud is instance-profiles'."
  type        = string
  default     = "cx2-2x4"
}

variable "image_name" {
  description = "The name of an existing OS image to use. You can list available images with the command 'ibmcloud is images'."
  type        = string
  default     = "ibm-ubuntu-22-04-1-minimal-amd64-3"
}

variable "allow_ip_spoofing" {
  description = "Allow IP spoofing on the bastion instance primary interface."
  type        = bool
  default     = false
}
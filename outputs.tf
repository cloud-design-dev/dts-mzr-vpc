output "local_vpc_zones" {
  description = "Public gateway zone mapping to actual IBM Cloud VPC zone names"
  value       = local.zone_mapping
}

output "vpc_id" {
  description = "ID of the IBM Cloud VPC"
  value       = ibm_is_vpc.lab.id
}

output "vpc_crn" {
  description = "Cloud Resource Name (CRN) of the IBM Cloud VPC"
  value       = ibm_is_vpc.lab.crn
}

output "default_security_group_id" {
  description = "ID of the Default Security Group for the VPC"
  value       = ibm_is_vpc.lab.default_security_group
}

output "default_security_group_crn" {
  description = "Cloud Resource Name (CRN) of the Default Security Group for the VPC"
  value       = ibm_is_vpc.lab.default_security_group_crn
}

output "default_network_acl_id" {
  description = "ID of the Default Access Control List for the VPC"
  value       = ibm_is_vpc.lab.default_network_acl
}

output "default_routing_table_id" {
  description = "ID of the Default Routing Table for the VPC"
  value       = ibm_is_vpc.lab.default_routing_table
}

output "vpc_subnet_ids" {
  description = "ID of the deployed VPC Subnets"
  value       = [for subnet in ibm_is_subnet.lab : subnet.id]
}

output "vpc_public_gateway_ids" {
  description = "ID of the deployed VPC Public Gateways"
  value       = [for gateway in ibm_is_public_gateway.lab : gateway.id]
}

output "vpc_address_prefix_ids" {
  description = "IBM Cloud VPC Address Prefix IDs"
  value = var.use_custom_prefix != false ? [
    for prefix in ibm_is_vpc_address_prefix.prefix : prefix.id
  ] : null
}

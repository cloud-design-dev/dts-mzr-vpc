output "local_vpc_zones" {
  value = local.zone_mapping
}

output "id" {
  value = ibm_is_vpc.lab.id
}

output "crn" {
  value = ibm_is_vpc.lab.crn
}

output "default_security_group_id" {
  value = ibm_is_vpc.lab.default_security_group
}

output "default_security_group_crn" {
  value = ibm_is_vpc.lab.default_security_group_crn
}

output "default_network_acl_id" {
  value = ibm_is_vpc.lab.default_network_acl
}

output "default_routing_table_id" {
  value = ibm_is_vpc.lab.default_routing_table
}

output "subnet_ids" {
  value = ibm_is_subnet.lab[*].id
}

output "subnet_zones" {
  value = ibm_is_subnet.lab[*].zone
}

output "total_ipv4_address_count" {
  value = ibm_is_subnet.lab[*].total_ipv4_address_count
}
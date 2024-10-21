output "local_vpc_zones" {
  value = local.zone_mapping
}

output "vpc_info" {
  value = ibm_is_vpc.lab
}
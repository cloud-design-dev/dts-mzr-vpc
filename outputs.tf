output "vpc_floating_ip" {
  value = ibm_is_floating_ip.zone_1.address
}

output "vpc_information" {
  value = ibm_is_vpc.vpc
}
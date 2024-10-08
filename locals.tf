locals {
  prefix = "${random_string.prefix.result}-demo"

  tags = [
    "owner:${var.owner}",
    "provider:ibm",
    "region:${var.region}"
  ]

  zones = length(data.ibm_is_zones.regional.zones)
  vpc_zones = {
    for zone in range(local.zones) : zone => {
      zone = "${var.region}-${zone + 1}"
    }
  }
}
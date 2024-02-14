locals {
  prefix      = var.project_prefix != "" ? var.project_prefix : "${random_string.prefix.0.result}"
  ssh_key_ids = var.existing_ssh_key != "" ? [data.ibm_is_ssh_key.sshkey[0].id] : [ibm_is_ssh_key.generated_key[0].id]

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
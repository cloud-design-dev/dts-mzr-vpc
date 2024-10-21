locals {
  prefix                    = var.project_prefix != "" ? var.project_prefix : "${random_string.lab_prefix.0.result}"
  address_prefix_management = var.use_custom_prefix != false ? "manual" : "auto"
  # Retrieve the list of zones from the data source
  zones        = data.ibm_is_zones.regional.zones
  region_zones = length(data.ibm_is_zones.regional.zones)
  vpc_zones = {
    for zone in range(local.region_zones) : zone => {
      zone = "${var.region}-${zone + 1}"
    }
  }
  # Create a mapping from "zone-1", "zone-2", etc., to actual zone names
  zone_mapping = {
    for index, zone_name in local.zones : "zone-${index + 1}" => zone_name
  }

  public_gateway_zones = [
    for zone_key, use_pg in var.use_public_gateways :
    local.zone_mapping[zone_key]
    if use_pg == true
  ]

  deploy_timestamp = formatdate("YYYYMMDD-HHmm", time_static.deploy_time.rfc3339)

  tags = [
    "created_at:${local.deploy_timestamp}",
    "owner:${var.owner_tag}",
  ]
}

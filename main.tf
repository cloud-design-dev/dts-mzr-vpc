resource "time_static" "deploy_time" {
  # Leave triggers empty to prevent the timestamp from changing
  triggers = {}
}

resource "ibm_is_vpc" "lab" {
  name                        = "${var.prefix}-vpc"
  resource_group              = var.resource_group_id
  classic_access              = var.classic_access
  address_prefix_management   = local.address_prefix_management
  default_network_acl_name    = "${var.prefix}-default-vpc-nacl"
  default_security_group_name = "${var.prefix}-default-vpc-sg"
  default_routing_table_name  = "${var.prefix}-default-vpc-rt"
  tags                        = concat(var.tags, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "ibm_is_vpc_address_prefix" "prefix" {
  count = var.use_custom_prefix != false ? 3 : 0

  name       = "${var.prefix}-address-prefix-${count.index}"
  zone       = local.vpc_zones[count.index].zone
  vpc        = ibm_is_vpc.lab.id
  cidr       = cidrsubnet(var.address_prefix, 4, count.index)
  is_default = true
}

resource "null_resource" "prefix_dependency" {
  depends_on = [
    ibm_is_vpc_address_prefix.prefix
  ]
}

resource "ibm_is_public_gateway" "lab" {
  for_each = toset(local.public_gateway_zones)

  name           = "${var.prefix}-pubgw-${each.key}"
  resource_group = var.resource_group_id
  vpc            = ibm_is_vpc.lab.id
  zone           = each.key
  tags           = concat(var.tags, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [
    null_resource.prefix_dependency
  ]
}

resource "ibm_is_subnet" "lab" {
  for_each = toset(local.zones)

  name                     = "${var.prefix}-subnet-${each.key}"
  resource_group           = var.resource_group_id
  vpc                      = ibm_is_vpc.lab.id
  zone                     = each.key
  total_ipv4_address_count = "32"
  tags                     = concat(var.tags, local.tags)

  public_gateway = contains(local.public_gateway_zones, each.key) ? ibm_is_public_gateway.lab[each.key].id : null

  lifecycle {
    ignore_changes = [tags]
  }
  depends_on = [
    null_resource.prefix_dependency, ibm_is_public_gateway.lab
  ]
}

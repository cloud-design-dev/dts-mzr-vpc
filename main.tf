module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.5"
  existing_resource_group_name = var.existing_resource_group
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
}

resource "ibm_is_vpc" "vpc" {
  name                        = "${local.prefix}-vpc"
  resource_group              = module.resource_group.resource_group_id
  classic_access              = var.classic_access
  address_prefix_management   = var.default_address_prefix
  default_network_acl_name    = "${local.prefix}-vpc-default-nacl"
  default_security_group_name = "${local.prefix}-vpc-default-sg"
  default_routing_table_name  = "${local.prefix}-vpc-default-rt"
  tags                        = local.tags
}

resource "ibm_is_public_gateway" "pgws" {
  count          = length(data.ibm_is_zones.regional.zones)
  name           = "${local.prefix}-zone-${count.index + 1}-pgw"
  resource_group = module.resource_group.resource_group_id
  vpc            = ibm_is_vpc.vpc.id
  zone           = local.vpc_zones[count.index].zone
  tags           = concat(local.tags, ["zone:${local.vpc_zones[count.index].zone}"])
}

resource "ibm_is_subnet" "frontend_subnets" {
  count                    = length(data.ibm_is_zones.regional.zones)
  name                     = "${local.prefix}-zone-${count.index + 1}-frontend-subnet"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.vpc_zones[count.index].zone
  tags                     = concat(local.tags, ["networktier:frontend", "zone:${local.vpc_zones[count.index].zone}"])
  total_ipv4_address_count = "128"
  public_gateway           = ibm_is_public_gateway.pgws[count.index].id
}

resource "ibm_is_subnet" "backend_subnets" {
  count                    = length(data.ibm_is_zones.regional.zones)
  name                     = "${local.prefix}-zone-${count.index + 1}-backend-subnet"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.vpc_zones[count.index].zone
  tags                     = concat(local.tags, ["networktier:backend", "zone:${local.vpc_zones[count.index].zone}"])
  total_ipv4_address_count = "256"
}

resource "ibm_is_floating_ip" "zone_1" {
  name           = "${local.prefix}-${local.vpc_zones[0].zone}-fip"
  resource_group = module.resource_group.resource_group_id
  zone           = local.vpc_zones[0].zone
  tags           = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_virtual_network_interface" "zone_1" {
  allow_ip_spoofing         = true
  auto_delete               = false
  enable_infrastructure_nat = true
  name                      = "${local.prefix}-${local.vpc_zones[0].zone}-vnic"
  subnet                    = ibm_is_subnet.frontend_subnets.0.id
  resource_group            = module.resource_group.resource_group_id
  security_groups           = [ibm_is_vpc.vpc.default_security_group]
  tags                      = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_virtual_network_interface_floating_ip" "vni_fip" {
  virtual_network_interface = ibm_is_virtual_network_interface.zone_1.id
  floating_ip               = ibm_is_floating_ip.zone_1.id
}

module "add_rules_to_default_vpc_security_group" {
  depends_on                   = [ibm_is_vpc.vpc]
  source                       = "terraform-ibm-modules/security-group/ibm"
  add_ibm_cloud_internal_rules = true
  use_existing_security_group  = true
  existing_security_group_name = ibm_is_vpc.vpc.default_security_group_name
  security_group_rules = [
    {
      name      = "allow-ssh-inbound"
      direction = "inbound"
      tcp = {
        port_min = 22
        port_max = 22
      }
      remote = var.allow_ssh_from
    }
  ]
  tags = local.tags
}
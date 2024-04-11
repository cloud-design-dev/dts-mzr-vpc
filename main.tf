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



resource "ibm_is_instance" "bastion" {
  name           = "${local.prefix}-bastion"
  vpc            = ibm_is_vpc.vpc.id
  image          = data.ibm_is_image.base.id
  profile        = var.instance_profile
  resource_group = module.resource_group.resource_group_id
  metadata_service {
    enabled            = true
    protocol           = "https"
    response_hop_limit = 5
  }

  boot_volume {
    auto_delete_volume = true
    name               = "${local.prefix}-bastion-boot-volume"
  }

  primary_network_attachment {
    name = "${local.prefix}-primary-att"
    virtual_network_interface {
      id = ibm_is_virtual_network_interface.bastion_vnic.id
    }
  }

  zone = local.vpc_zones[0].zone
  keys = [data.ibm_is_ssh_key.sshkey.id]
  tags = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.prefix}-bastion-public-ip"
  resource_group = module.resource_group.resource_group_id
  zone           = local.vpc_zones[0].zone
  tags           = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_virtual_network_interface" "bastion_vnic" {
  allow_ip_spoofing         = true
  auto_delete               = false
  enable_infrastructure_nat = true
  name                      = "${local.prefix}-bastion-vnic"
  subnet                    = ibm_is_subnet.frontend_subnets.0.id
  resource_group            = module.resource_group.resource_group_id
  security_groups           = [module.bastion_security_group.security_group_id]
  tags                      = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_virtual_network_interface_floating_ip" "vni_fip" {
  virtual_network_interface = ibm_is_virtual_network_interface.bastion_vnic.id
  floating_ip               = ibm_is_floating_ip.bastion.id
}

resource "ibm_is_instance" "hashistack" {
  count          = 5
  name           = "${local.prefix}-hs-instance-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc.id
  image          = data.ibm_is_image.base.id
  profile        = var.instance_profile
  resource_group = module.resource_group.resource_group_id
  metadata_service {
    enabled            = true
    protocol           = "https"
    response_hop_limit = 5
  }

  boot_volume {
    auto_delete_volume = true
    name               = "${local.prefix}-${count.index + 1}-boot-volume"
  }

  primary_network_interface {
    subnet            = ibm_is_subnet.backend_subnets.0.id
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.consul_security_group.security_group_id, module.nomad_security_group.security_group_id]
  }

  zone = local.vpc_zones[0].zone
  keys = [data.ibm_is_ssh_key.sshkey.id]
  tags = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}
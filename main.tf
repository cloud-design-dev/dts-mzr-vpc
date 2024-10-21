resource "random_string" "lab_prefix" {
  count   = var.project_prefix != "" ? 0 : 1
  length  = 4
  special = false
  numeric = false
  upper   = false
}

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.5"
  resource_group_name          = var.existing_resource_group == null ? "${local.prefix}-resource-group" : null
  existing_resource_group_name = var.existing_resource_group
}

resource "tls_private_key" "ssh" {
  count     = var.existing_ssh_key != "" ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "generated_key" {
  count          = var.existing_ssh_key != "" ? 0 : 1
  name           = "${local.prefix}-${var.region}-sshkey"
  resource_group = module.resource_group.resource_group_id
  public_key     = tls_private_key.ssh.0.public_key_openssh
  tags           = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}


resource "local_file" "ssh_key" {
  count           = var.existing_ssh_key != "" ? 0 : 1
  content         = tls_private_key.ssh.0.private_key_pem
  filename        = "${path.module}/generated_key_rsa"
  file_permission = "0600"
}

resource "ibm_is_vpc" "lab" {
  name                        = "${local.prefix}-vpc"
  resource_group              = module.resource_group.resource_group_id
  classic_access              = var.classic_access
  address_prefix_management   = local.address_prefix_management
  default_network_acl_name    = "${local.prefix}-default-vpc-nacl"
  default_security_group_name = "${local.prefix}-default-vpc-sg"
  default_routing_table_name  = "${local.prefix}-default-vpc-rt"
  tags                        = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

# resource "null_resource" "prefix_dependency" {
#   depends_on = [
#     ibm_is_vpc_address_prefix.prefix
#   ]
# }


resource "ibm_is_vpc_address_prefix" "prefix" {
  count = var.use_custom_prefix != false ? 3 : 0

  name       = "${local.prefix}-address-prefix-${count.index}"
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

  name           = "${local.prefix}-pubgw-${each.key}"
  resource_group = module.resource_group.resource_group_id
  vpc            = ibm_is_vpc.lab.id
  zone           = each.key
  tags           = local.tags

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [
    null_resource.prefix_dependency
  ]
}

resource "ibm_is_subnet" "lab" {
  for_each = toset(local.zones)

  name                     = "${local.prefix}-subnet-${each.key}"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.lab.id
  zone                     = each.key
  total_ipv4_address_count = "32"
  tags                     = local.tags

  public_gateway = contains(local.public_gateway_zones, each.key) ? ibm_is_public_gateway.lab[each.key].id : null

  lifecycle {
    ignore_changes = [tags]
  }
  depends_on = [
    null_resource.prefix_dependency, ibm_is_public_gateway.lab
  ]
}
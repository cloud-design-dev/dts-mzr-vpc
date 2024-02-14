module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.1.1"
  resource_group_name          = var.existing_resource_group == null ? "${local.prefix}-resource-group" : null
  existing_resource_group_name = var.existing_resource_group
}

resource "random_string" "prefix" {
  count   = var.project_prefix != "" ? 0 : 1
  length  = 4
  special = false
  upper   = false
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "generated_key" {
  count          = var.existing_ssh_key != "" ? 0 : 1
  name           = "${local.prefix}-${var.region}-key"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = module.resource_group.resource_group_id
  tags           = local.tags
}

resource "ibm_sm_secret_group" "sm_secret_group" {
  count       = var.existing_ssh_key != "" ? 0 : 1
  instance_id = data.ibm_resource_instance.sm_instance.guid
  region      = "us-south"
  name        = "${local.prefix}-secret-group"
  description = "Secret group for storing private and public SSH keys."
}

# resource "null_resource" "create_private_key" {
#   count = var.existing_ssh_key != "" ? 0 : 1
#   provisioner "local-exec" {
#     command = <<-EOT
#       echo '${tls_private_key.ssh.private_key_pem}' > ./'${local.prefix}'.pem
#       chmod 400 ./'${local.prefix}'.pem
#     EOT
#   }
# }

resource "ibm_sm_arbitrary_secret" "ssh_privkey_secret" {
  count           = var.existing_ssh_key != "" ? 0 : 1
  name            = "${local.prefix}-ssh-private-key"
  instance_id     = data.ibm_resource_instance.sm_instance.guid
  region          = "us-south"
  description     = "Extended description for this secret."
  payload         = tls_private_key.ssh.private_key_pem
  secret_group_id = ibm_sm_secret_group.sm_secret_group.0.secret_group_id
}

resource "ibm_sm_arbitrary_secret" "ssh_pubkey_secret" {
  count           = var.existing_ssh_key != "" ? 0 : 1
  name            = "${local.prefix}-ssh-public-key"
  instance_id     = data.ibm_resource_instance.sm_instance.guid
  region          = "us-south"
  description     = "Extended description for this secret."
  payload         = tls_private_key.ssh.public_key_openssh
  secret_group_id = ibm_sm_secret_group.sm_secret_group.0.secret_group_id
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

module "bastion_security_group" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "2.5.0"
  add_ibm_cloud_internal_rules = true
  vpc_id                       = ibm_is_vpc.vpc.id
  resource_group               = module.resource_group.resource_group_id
  security_group_name          = "${local.prefix}-bastion-sg"
  security_group_rules = [{
    name      = "allow-ssh-inbound-office"
    direction = "inbound"
    remote    = var.allow_ssh_from
    tcp = {
      port_min = 22
      port_max = 22
    }
    },
    {
      name      = "allow-ssh-outbound-all"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 22
        port_max = 22
      }
    },
    {
      name      = "allow-http-outbound-all"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name      = "allow-https-outbound-all"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 443
        port_max = 443
      }
    }
  ]
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

  primary_network_interface {
    subnet            = ibm_is_subnet.frontend_subnets.0.id
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.bastion_security_group.security_group_id]
  }

  zone = local.vpc_zones[0].zone
  keys = local.ssh_key_ids
  tags = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_floating_ip" "bastion" {
  name           = "${local.prefix}-bastion-public-ip"
  resource_group = module.resource_group.resource_group_id
  target         = ibm_is_instance.bastion.primary_network_interface[0].id
  tags           = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}
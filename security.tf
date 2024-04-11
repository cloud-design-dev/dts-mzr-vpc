module "bastion_security_group" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "2.5.0"
  add_ibm_cloud_internal_rules = true
  vpc_id                       = ibm_is_vpc.vpc.id
  resource_group               = module.resource_group.resource_group_id
  security_group_name          = "${local.prefix}-bastion-sg"
  security_group_rules = [{
    name      = "allow-ssh-from-do-inbound"
    direction = "inbound"
    remote    = var.allow_ssh_do_instance
    tcp = {
      port_min = 22
      port_max = 22
    }
    },
    {
      name      = "allow-ssh-from-home-inbound"
      direction = "inbound"
      remote    = var.allow_ssh_homelab
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

module "consul_security_group" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "2.5.0"
  add_ibm_cloud_internal_rules = true
  vpc_id                       = ibm_is_vpc.vpc.id
  resource_group               = module.resource_group.resource_group_id
  security_group_name          = "${local.prefix}-consul-sg"
  security_group_rules = [{
    name      = "allow-ssh-from-bastion-inbound"
    direction = "inbound"
    remote    = module.bastion_security_group.security_group_id
    tcp = {
      port_min = 22
      port_max = 22
    }
    },
    {
      name      = "allow-consul-tcp-dns-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 8600
        port_max = 8600
      }
    },
    {
      name      = "allow-consul-udp-dns-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      udp = {
        port_min = 8600
        port_max = 8600
      }
    },
    {
      name      = "allow-consul-http-https-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 8500
        port_max = 8501
      }
    },
    {
      name      = "allow-consul-rcp-lan-wan-tcp-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 8300
        port_max = 8302
      }
    },
    {
      name      = "allow-consul-lan-wan-udp-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 8301
        port_max = 8302
      }
    },
    {
      name      = "allow-http-all-outbound"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name      = "allow-https-all-outbound"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 443
        port_max = 443
      }
    }
  ]
}

module "nomad_security_group" {
  source                       = "terraform-ibm-modules/security-group/ibm"
  version                      = "2.5.0"
  add_ibm_cloud_internal_rules = true
  vpc_id                       = ibm_is_vpc.vpc.id
  resource_group               = module.resource_group.resource_group_id
  security_group_name          = "${local.prefix}-nomad-sg"
  security_group_rules = [{
    name      = "allow-ssh-from-bastion-inbound"
    direction = "inbound"
    remote    = module.bastion_security_group.security_group_id
    tcp = {
      port_min = 22
      port_max = 22
    }
    },
    {
      name      = "allow-nomad-http-rpc-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 4646
        port_max = 4648
      }
    },
    {
      name      = "allow-nomad-serf-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      udp = {
        port_min = 4648
        port_max = 4648
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
    },
    {
      name      = "allow-http-outbound-all"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 80
        port_max = 80
      }
    }
  ]
}
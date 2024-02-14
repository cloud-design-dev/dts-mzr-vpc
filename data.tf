data "ibm_is_zones" "regional" {
  region = var.region
}

data "ibm_is_ssh_key" "sshkey" {
  count = var.existing_ssh_key != "" ? 1 : 0
  name  = var.existing_ssh_key
}

data "ibm_is_image" "base" {
  name = var.image_name
}

data "ibm_resource_instance" "sm_instance" {
  name              = "dts-lab-sm-instance"
  location          = "us-south"
  resource_group_id = module.resource_group.resource_group_id
  service           = "secrets-manager"
}
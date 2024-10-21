# Overview

This module deploys a VPC in IBM Cloud with the following characteristics:

- VPC with 3 zones
- Public gateways in any of the 3 zones based on the input
- Subnets in all 3 zones. If the zone has a public gagteway, the subnet will be attached to it
- Classic access enabled/disabled based on the input
- Can create an SSH key or use an existing one
- Can create a new resource group or use an existing one
- Ability to support custom address prefixes for the VPC

## Diagram

![Overview of deployed resources](./mzr-vpc-module.png)

Things that have not been implemented yet, but I am working on:

- [ ] Ability to enable Flowlogs for a given VPC. This requires a cloud object storage instance as well as the buckets to store the logs. This also requires a service to service authorization between the 2 services. I have the logic in place, but I need to test it out.

## Get Started

### Prerequisites

- Terraform installed locally
- IBM Cloud API Key

### Steps

1. Clone the repository

```shell
git clone https://github.ibm.com/IBMCloudTech/ibmcloud-mzr-vpc.git
cd ibmcloud-mzr-vpc
```

2. Copy `terraform-tfvars-example` to `terraform.tfvars` and fill in the required values

```shell
cp terraform-tfvars-example terraform.tfvars
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_prefix"></a> [address\_prefix](#input\_address\_prefix) | The address prefix to use if address\_prefix\_management is set to manual. This will be split in to three prefixes, one for each zone. | `string` | `"172.16.0.0/16"` | no |
| <a name="input_classic_access"></a> [classic\_access](#input\_classic\_access) | Indicates if the VPC will have Classic Access. | `bool` | `false` | no |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | The name of an existing resource group where the VPC will be created. If not provided a new Resource group will be created. | `string` | `""` | no |
| <a name="input_existing_ssh_key"></a> [existing\_ssh\_key](#input\_existing\_ssh\_key) | The name of an existing SSH key to use for provisioning resources. If one is not provided, a new key will be generated. | `string` | `""` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | IBM Cloud API key to use for deployment. | `string` | n/a | yes |
| <a name="input_owner_tag"></a> [owner\_tag](#input\_owner\_tag) | The owner tag to assign to all resources. | `string` | n/a | yes |
| <a name="input_project_prefix"></a> [project\_prefix](#input\_project\_prefix) | Prefix to assign to all deployed resources. If not provided a randome string will be generated. | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where the VPC and related resources will be deployed. | `string` | `""` | no |
| <a name="input_use_custom_prefix"></a> [use\_custom\_prefix](#input\_use\_custom\_prefix) | Indicates if custom address prefixes will be used. | `bool` | `false` | no |
| <a name="input_use_public_gateways"></a> [use\_public\_gateways](#input\_use\_public\_gateways) | Create a public gateway in any of the three zones set to `true`. | <pre>object({<br>    zone-1 = optional(bool)<br>    zone-2 = optional(bool)<br>    zone-3 = optional(bool)<br>  })</pre> | <pre>{<br>  "zone-1": true,<br>  "zone-2": true,<br>  "zone-3": false<br>}</pre> | no |


3. Initialize the Terraform workspace

```shell
terraform init
```

4. Plan and apply the Terraform configuration

```shell
terraform plan -out "$(terraform workspace show).tfplan"

terraform apply "$(terraform workspace show).tfplan"
```

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_local_vpc_zones"></a> [local\_vpc\_zones](#output\_local\_vpc\_zones) | n/a |
| <a name="output_vpc_info"></a> [vpc\_info](#output\_vpc\_info) | n/a |
<!-- END_TF_DOCS -->

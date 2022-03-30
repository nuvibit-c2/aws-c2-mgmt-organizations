
# Terraform workspace repository for aws-c2-org-mgmt

<!-- LOGO -->
<a href="https://nuvibit.com">
    <img src="https://nuvibit.com/images/logo/logo-nuvibit-square.png" alt="nuvibit logo" title="nuvibit" align="right" width="100" />
</a>

<!-- SHIELDS -->
[![Maintained by nuvibit.com][nuvibit-shield]][nuvibit-url]
[![Terraform Version][terraform-version-shield]][terraform-version-url]

<!-- DESCRIPTION -->
[Terraform workspace][terraform-workspace-url] repository to deploy resources on [AWS][aws-url]

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >3.15 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >3.15 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_account_context"></a> [account\_context](#module\_account\_context) | github.com/nuvibit/terraform-aws-account-context.git | main |
| <a name="module_account_vendor"></a> [account\_vendor](#module\_account\_vendor) | github.com/nuvibit/terraform-aws-account-vendor.git | v1.0.0 |
| <a name="module_aws-c2"></a> [aws-c2](#module\_aws-c2) | github.com/nuvibit/terraform-aws-sso.git//modules/azuread-org-sso | n/a |
| <a name="module_foundation_security_provisioner"></a> [foundation\_security\_provisioner](#module\_foundation\_security\_provisioner) | github.com/nuvibit/terraform-aws-foundation-security.git//modules/iam-roles-provisioner | main |
| <a name="module_foundation_settings_security"></a> [foundation\_settings\_security](#module\_foundation\_settings\_security) | github.com/nuvibit/terraform-aws-org-mgmt.git//modules/ssm-parameters | main |
| <a name="module_master_config"></a> [master\_config](#module\_master\_config) | github.com/nuvibit/terraform-aws-org-mgmt.git | add-cloudtrail |
| <a name="module_org_cloudtrail"></a> [org\_cloudtrail](#module\_org\_cloudtrail) | github.com/nuvibit/terraform-aws-foundation-security.git//modules/org-cloudtrail | move-org-mgmt-configs |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_organizational_units.ou](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_units) | data source |
| [aws_organizations_resource_tags.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_resource_tags) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TF_VAR_ARM_CLIENT_SECRET"></a> [TF\_VAR\_ARM\_CLIENT\_SECRET](#input\_TF\_VAR\_ARM\_CLIENT\_SECRET) | --------------------------------------------------------------------------------------------------------------------- ¦ AZURE CREDENTIALS - LOCAL EXEC --------------------------------------------------------------------------------------------------------------------- | `any` | n/a | yes |
| <a name="input_git_token"></a> [git\_token](#input\_git\_token) | the git token | `string` | n/a | yes |
| <a name="input_resource_name_prefix"></a> [resource\_name\_prefix](#input\_resource\_name\_prefix) | Alphanumeric prefix for all the resource names in this module. | `string` | `""` | no |
| <a name="input_resource_name_suffix"></a> [resource\_name\_suffix](#input\_resource\_name\_suffix) | Alphanumeric suffix for all the resource names in this module. | `string` | `""` | no |
| <a name="input_resource_tags"></a> [resource\_tags](#input\_resource\_tags) | A map of tags to assign to the resources in this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_context"></a> [account\_context](#output\_account\_context) | n/a |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | n/a |
| <a name="output_aws_organizations_organization"></a> [aws\_organizations\_organization](#output\_aws\_organizations\_organization) | n/a |
| <a name="output_aws_organizations_organizational_units"></a> [aws\_organizations\_organizational\_units](#output\_aws\_organizations\_organizational\_units) | n/a |
| <a name="output_branding_ou_id"></a> [branding\_ou\_id](#output\_branding\_ou\_id) | n/a |
| <a name="output_foundation_security_provisioner_role_arn"></a> [foundation\_security\_provisioner\_role\_arn](#output\_foundation\_security\_provisioner\_role\_arn) | n/a |
| <a name="output_org_id"></a> [org\_id](#output\_org\_id) | n/a |
| <a name="output_organization_root_id"></a> [organization\_root\_id](#output\_organization\_root\_id) | n/a |
| <a name="output_region"></a> [region](#output\_region) | n/a |
| <a name="output_tenant_ou_ids"></a> [tenant\_ou\_ids](#output\_tenant\_ou\_ids) | n/a |

<!--- END_TF_DOCS --->

<!-- AUTHORS -->
## Authors
This repository is maintained by [Nuvibit][nuvibit-url] with help from [these amazing contributors][contributors-url]

<!-- COPYRIGHT -->
<br />
<br />
<p align="center">Copyright &copy; 2021 Nuvibit AG</p>

<!-- MARKDOWN LINKS & IMAGES -->
[nuvibit-shield]: https://img.shields.io/badge/maintained%20by-nuvibit.com-%235849a6.svg?style=flat&color=1c83ba
[nuvibit-url]: https://nuvibit.com
[terraform-version-shield]: https://img.shields.io/badge/tf-%3E%3D0.15.0-blue.svg?style=flat&color=blueviolet
[terraform-version-url]: https://www.terraform.io/upgrade-guides/0-15.html
[contributors-url]: https://github.com/nuvibit/aws-c2-org-mgmt/graphs/contributors
[terraform-workspace-url]: https://app.terraform.io/app/nuvibit/workspaces/aws-c2-org-mgmt
[aws-url]: https://aws.amazon.com

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.10, != 4.34 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 5.0 |
| <a name="requirement_tfe"></a> [tfe](#requirement\_tfe) | ~> 0.31 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.10, != 4.34 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ntc_parameters_bucket"></a> [ntc\_parameters\_bucket](#module\_ntc\_parameters\_bucket) | github.com/nuvibit/terraform-aws-ntc-parameters | feat-init |
| <a name="module_org_mgmt_pipline"></a> [org\_mgmt\_pipline](#module\_org\_mgmt\_pipline) | app.terraform.io/nuvibit/org-mgmt-piplines/aws | 1.2.2 |
| <a name="module_sso_identity_center"></a> [sso\_identity\_center](#module\_sso\_identity\_center) | app.terraform.io/nuvibit/sso/aws | 1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_organizations_account.org_management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_resource_tags.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_resource_tags) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The current account id |
| <a name="output_ntc_parameters"></a> [ntc\_parameters](#output\_ntc\_parameters) | Map of all ntc core parameters |
| <a name="output_region"></a> [region](#output\_region) | The current region name |
<!-- END_TF_DOCS -->

<!-- AUTHORS -->
## Authors
This repository is maintained by [Nuvibit][nuvibit-url] with help from [these amazing contributors][contributors-url]

<!-- COPYRIGHT -->
<br />
<br />
<p align="center">Copyright &copy; 2022 Nuvibit AG</p>

<!-- MARKDOWN LINKS & IMAGES -->
[nuvibit-shield]: https://img.shields.io/badge/maintained%20by-nuvibit.com-%235849a6.svg?style=flat&color=1c83ba
[nuvibit-url]: https://nuvibit.com
[terraform-version-shield]: https://img.shields.io/badge/tf-%3E%3D0.15.0-blue.svg?style=flat&color=blueviolet
[terraform-version-url]: https://www.terraform.io/upgrade-guides/0-15.html
[contributors-url]: https://github.com/nuvibit/aws-c2-org-mgmt/graphs/contributors
[terraform-workspace-url]: https://app.terraform.io/app/nuvibit/workspaces/aws-c2-org-mgmt
[aws-url]: https://aws.amazon.com
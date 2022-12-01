
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
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
| <a name="module_account_baseline_pipline"></a> [account\_baseline\_pipline](#module\_account\_baseline\_pipline) | app.terraform.io/nuvibit/org-mgmt-piplines/aws | 1.2.2 |
| <a name="module_account_lifecycle_pipline"></a> [account\_lifecycle\_pipline](#module\_account\_lifecycle\_pipline) | app.terraform.io/nuvibit/org-mgmt-piplines/aws | 1.2.2 |
| <a name="module_account_vendor"></a> [account\_vendor](#module\_account\_vendor) | app.terraform.io/nuvibit/account-vendor/aws | 1.4.0 |
| <a name="module_foundation_settings"></a> [foundation\_settings](#module\_foundation\_settings) | app.terraform.io/nuvibit/core-parameters/aws//modules/reader | 1.0.0 |
| <a name="module_main_config"></a> [main\_config](#module\_main\_config) | app.terraform.io/nuvibit/org-mgmt/aws | 1.5.2 |
| <a name="module_org_mgmt_parameters"></a> [org\_mgmt\_parameters](#module\_org\_mgmt\_parameters) | app.terraform.io/nuvibit/core-parameters/aws | 1.0.0 |
| <a name="module_org_mgmt_pipline"></a> [org\_mgmt\_pipline](#module\_org\_mgmt\_pipline) | app.terraform.io/nuvibit/org-mgmt-piplines/aws | 1.2.2 |
| <a name="module_parameter_roles"></a> [parameter\_roles](#module\_parameter\_roles) | app.terraform.io/nuvibit/core-parameters/aws//modules/iam-roles | 1.0.0 |
| <a name="module_sso_org_admins"></a> [sso\_org\_admins](#module\_sso\_org\_admins) | github.com/nuvibit/terraform-aws-sso-gen2 | feat-init2 |
| <a name="module_sso_permission_sets"></a> [sso\_permission\_sets](#module\_sso\_permission\_sets) | github.com/nuvibit/terraform-aws-sso-gen2//modules/permission-sets | feat-init2 |

## Resources

| Name | Type |
|------|------|
| [aws_organizations_account.org_management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_resource_tags.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_resource_tags) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssoadmin_instances.sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The current account id |
| <a name="output_account_parameters"></a> [account\_parameters](#output\_account\_parameters) | The account parameter values |
| <a name="output_organization_root_id"></a> [organization\_root\_id](#output\_organization\_root\_id) | The organization root id |
| <a name="output_region"></a> [region](#output\_region) | The current region name |
| <a name="output_tenant_ou_ids"></a> [tenant\_ou\_ids](#output\_tenant\_ou\_ids) | A List of tenant ou ids |
<!-- END_TF_DOCS -->

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

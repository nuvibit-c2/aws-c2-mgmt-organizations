<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.33 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.33 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ntc_parameters_reader"></a> [ntc\_parameters\_reader](#module\_ntc\_parameters\_reader) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader | 1.1.2 |
| <a name="module_ntc_parameters_writer"></a> [ntc\_parameters\_writer](#module\_ntc\_parameters\_writer) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer | 1.1.2 |
| <a name="module_organizations"></a> [organizations](#module\_organizations) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations | 1.0.2 |
| <a name="module_service_control_policy_templates"></a> [service\_control\_policy\_templates](#module\_service\_control\_policy\_templates) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-scp-templates | 1.0.2 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.ntc_org_account_reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ntc_org_account_reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ntc_org_account_reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ntc_org_account_reader_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The current account id |
| <a name="output_default_region"></a> [default\_region](#output\_default\_region) | The default region name |
| <a name="output_ntc_parameters"></a> [ntc\_parameters](#output\_ntc\_parameters) | Map of all ntc parameters |
<!-- END_TF_DOCS -->
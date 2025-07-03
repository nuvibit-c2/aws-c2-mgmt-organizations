<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- terraform (>= 1.3.0)

- aws (~> 5.33)

## Providers

The following providers are used by this module:

- aws (~> 5.33)

## Modules

The following Modules are called:

### ntc\_delegated\_admins\_euc1

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/regional-admin-delegations

Version: 1.5.0

### ntc\_delegated\_admins\_euc2

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/regional-admin-delegations

Version: 1.5.0

### ntc\_delegated\_admins\_use1

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/regional-admin-delegations

Version: 1.5.0

### ntc\_guardrail\_templates

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-guardrail-templates

Version: 1.2.1

### ntc\_organization\_quotas

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/service-quotas

Version: 1.5.0

### ntc\_organizations

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations

Version: 1.5.0

### ntc\_parameters\_reader

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader

Version: 1.1.4

### ntc\_parameters\_writer

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer

Version: 1.1.4

## Resources

The following resources are used by this module:

- [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) (data source)
- [aws_region.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data source)

## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### account\_id

Description: The current account id

### default\_region

Description: The default region name

### ntc\_parameters

Description: Map of all ntc parameters
<!-- END_TF_DOCS -->
<!-- LOGO -->
<a href="https://nuvibit.com">
    <img src="https://nuvibit.com/images/logo/logo-nuvibit-badge.png" alt="nuvibit logo" title="nuvibit" align="right" width="100" />
</a>

# AWS Core Parameters S3 Terraform module

<!-- DESCRIPTION -->
[Terraform][terraform-url] module to store foundation core parameters in S3 on [AWS][aws-url]

<!-- USAGE -->
## Usage
```hcl
module "example" {
  # source = "GIT_URL/terraform-aws-core-parameters-s3"
  source = "TFE_ORG/core-parameters-s3/aws"
  version = "~> 1.0"

  name  = "template"
}
```

<!-- EXAMPLES -->
## Examples
- [`examples/complete`][complete-module-test-url]

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

<!-- COPYRIGHT -->
<br />
<br />
<p align="center">Copyright &copy; 2023 Nuvibit AG</p>

<!-- MARKDOWN LINKS & IMAGES -->
[nuvibit-shield]: https://img.shields.io/badge/maintained%20by-nuvibit.com-%235849a6.svg?style=flat&color=1c83ba
[nuvibit-url]: https://nuvibit.com
[terraform-version-shield]: https://img.shields.io/badge/terraform-%3E%3D1.0.0-blue.svg?style=flat&color=blueviolet
[terraform-version-url]: https://www.terraform.io/upgrade-guides/1-0.html
[release-shield]: https://img.shields.io/github/v/release/nuvibit/terraform-aws-core-parameters-s3?style=flat&color=success
[architecture-png]: https://github.com/nuvibit/terraform-aws-core-parameters-s3/blob/main/docs/architecture.png?raw=true
[release-url]: https://github.com/nuvibit/terraform-aws-core-parameters-s3/releases
[contributors-url]: https://github.com/nuvibit/terraform-aws-core-parameters-s3/graphs/contributors
[license-url]: https://github.com/nuvibit/terraform-aws-core-parameters-s3/tree/main/LICENSE
[terraform-url]: https://www.terraform.io
[aws-url]: https://aws.amazon.com
[complete-module-test-url: https://github.com/nuvibit/terraform-aws-core-parameters-s3/tree/main/examples/complete

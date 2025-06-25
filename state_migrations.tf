# existing resources can be imported to be managed by NTC - this can be usefull to avoid downtime or recreating critical resources
# import blocks are only available in Terraform v1.5.0 and later

/*
import {
  # AWS Organization cannot simply be deleted if accounts exist and is therefore easier to import
  to = module.ntc_organizations.aws_organizations_organization.ntc_org[0]
  id = "o-m29e8d9awz"
}
*/
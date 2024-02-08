import {
    to = module.organizations.aws_organizations_organization.ntc_org[0]
    id = "o-m29e8d9awz"
}

import {
    to = module.organizations.module.org_cloudtrail[0].aws_cloudtrail.ntc_cloudtrail
    id = "arn:aws:cloudtrail:eu-central-1:228120440352:trail/organization-trail"
}

import {
    to = aws_iam_role.ntc_org_account_reader
    id = "ntc-org-account-reader"
}

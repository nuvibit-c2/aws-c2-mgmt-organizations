import {
    to = module.organizations.aws_organizations_organizational_unit.ntc_nested_ou_level1["/root/workloads"]
    id = "ou-6gf5-6ltp3mjf"
}
import {
    to = module.organizations.aws_organizations_organizational_unit.ntc_nested_ou_level1["/root/infrastructure"]
    id = "ou-6gf5-uktkya48"
}
import {
    to = module.organizations.aws_organizations_organizational_unit.ntc_nested_ou_level1["/root/security"]
    id = "ou-6gf5-ebbpq9yb"
}
import {
    to = module.organizations.aws_organizations_organizational_unit.ntc_nested_ou_level1["/root/sandbox"]
    id = "ou-6gf5-yvm8rkvb"
}
import {
    to = module.organizations.aws_organizations_organizational_unit.ntc_nested_ou_level1["/root/suspended"]
    id = "ou-6gf5-hyl8xkvz"
}
import {
    to = module.organizations.aws_organizations_policy.ntc_scp["scp_workloads_ou"]
    id = "p-u4s7wj22"
}
import {
    to = module.organizations.aws_organizations_policy.ntc_scp["scp_suspended_ou"]
    id = "p-dgcq8mhw"
}
import {
    to = module.organizations.aws_organizations_policy.ntc_scp["scp_root_ou"]
    id = "p-ew4wrqqn"
}

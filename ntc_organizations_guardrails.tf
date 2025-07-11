# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC GUARDRAIL TEMPLATES
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_guardrail_templates" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-guardrail-templates?ref=1.2.1"

  # service control policies (SCPs) can apply permission guardrails at the organization, organizational unit, or account level
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
  service_control_policy_templates = [
    {
      policy_name        = "scp_root_ou"
      policy_description = "Deny leaving the organization and root user actions except for centralized root privilege tasks"
      target_ou_paths    = ["/root"]
      template_names = [
        "deny_leaving_organizations",
        "deny_actions_as_root_except_centralized_root"
      ]
    },
    {
      policy_name        = "scp_suspended_ou"
      policy_description = "Deny all actions for suspended accounts"
      target_ou_paths = [
        "/root/suspended",
        "/root/transitional"
      ]
      template_names = ["deny_all"]
      # template specific parameters
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    {
      policy_name        = "scp_workloads_ou"
      policy_description = "Deny all actions outside allowed regions except global services"
      target_ou_paths    = ["/root/workloads"]
      template_names     = ["deny_outside_allowed_regions"]
      # template specific parameters
      allowed_regions = [
        "eu-central-1",
        "eu-central-2"
      ]
      whitelist_for_other_regions = [
        # allowed global actions
        "a4b:*",
        "acm:*",
        "aws-marketplace-management:*",
        "aws-marketplace:*",
        "aws-portal:*",
        "budgets:*",
        "ce:*",
        "chime:*",
        "cloudfront:*",
        "config:*",
        "cur:*",
        "directconnect:*",
        "ec2:DescribeRegions",
        "ec2:DescribeTransitGateways",
        "ec2:DescribeVpnGateways",
        "fms:*",
        "globalaccelerator:*",
        "health:*",
        "iam:*",
        "importexport:*",
        "kms:*",
        "mobileanalytics:*",
        "networkmanager:*",
        "organizations:*",
        "pricing:*",
        "route53:*",
        "route53domains:*",
        "route53-recovery-cluster:*",
        "route53-recovery-control-config:*",
        "route53-recovery-readiness:*",
        "s3:GetAccountPublic*",
        "s3:ListAllMyBuckets",
        "s3:ListMultiRegionAccessPoints",
        "s3:PutAccountPublic*",
        "shield:*",
        "sts:*",
        "support:*",
        "trustedadvisor:*",
        "waf-regional:*",
        "waf:*",
        "wafv2:*",
        "wellarchitected:*"
      ]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    {
      policy_name        = "scp_sandbox_ou"
      policy_description = "Deny all actions outside allowed regions except global services"
      policy_type        = "SERVICE_CONTROL_POLICY"
      target_ou_paths    = ["/root/sandbox"]
      template_names = [
        "deny_outside_allowed_regions",
        "deny_inside_allowed_regions"
      ]
      # template specific parameters
      allowed_regions = [
        "eu-central-1",
        "eu-central-2",
        "eu-west-1",
        "us-east-1"
      ]
      whitelist_for_other_regions = [
        # allowed global actions
        "a4b:*",
        "acm:*",
        "aws-marketplace-management:*",
        "aws-marketplace:*",
        "aws-portal:*",
        "budgets:*",
        "ce:*",
        "chime:*",
        "cloudfront:*",
        "config:*",
        "cur:*",
        "directconnect:*",
        "ec2:DescribeRegions",
        "ec2:DescribeTransitGateways",
        "ec2:DescribeVpnGateways",
        "fms:*",
        "globalaccelerator:*",
        "health:*",
        "iam:*",
        "importexport:*",
        "kms:*",
        "mobileanalytics:*",
        "networkmanager:*",
        "organizations:*",
        "pricing:*",
        "route53:*",
        "route53domains:*",
        "route53-recovery-cluster:*",
        "route53-recovery-control-config:*",
        "route53-recovery-readiness:*",
        "s3:GetAccountPublic*",
        "s3:ListAllMyBuckets",
        "s3:ListMultiRegionAccessPoints",
        "s3:PutAccountPublic*",
        "shield:*",
        "sts:*",
        "support:*",
        "trustedadvisor:*",
        "waf-regional:*",
        "waf:*",
        "wafv2:*",
        "wellarchitected:*"
      ]
      whitelist_for_allowed_regions = [
        # allowed global actions
        "a4b:*",
        "acm:*",
        "aws-marketplace-management:*",
        "aws-marketplace:*",
        "aws-portal:*",
        "budgets:*",
        "ce:*",
        "chime:*",
        "cloudfront:*",
        "config:*",
        "cur:*",
        "directconnect:*",
        "ec2:DescribeRegions",
        "ec2:DescribeTransitGateways",
        "ec2:DescribeVpnGateways",
        "fms:*",
        "globalaccelerator:*",
        "health:*",
        "iam:*",
        "importexport:*",
        "kms:*",
        "mobileanalytics:*",
        "networkmanager:*",
        "organizations:*",
        "pricing:*",
        "route53:*",
        "route53domains:*",
        "route53-recovery-cluster:*",
        "route53-recovery-control-config:*",
        "route53-recovery-readiness:*",
        "s3:GetAccountPublic*",
        "s3:ListAllMyBuckets",
        "s3:ListMultiRegionAccessPoints",
        "s3:PutAccountPublic*",
        "shield:*",
        "sts:*",
        "support:*",
        "trustedadvisor:*",
        "waf-regional:*",
        "waf:*",
        "wafv2:*",
        "wellarchitected:*",
        # allowed regional actions
        "lambda:*",
        "s3:*",
        "ec2:*"
      ]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    # SCP to only allow services in the C5 compliance scope
    # https://aws.amazon.com/compliance/services-in-scope/C5/
    {
      policy_name        = "scp_c5_compliance"
      policy_description = "Allow only C5 compliant services in EU regions"
      policy_type        = "SERVICE_CONTROL_POLICY"
      target_ou_paths    = ["/root/sandbox"] # change to '/root' to enforce for entire organization
      template_names = [
        # scp templates to deny actions in all regions
        "deny_outside_allowed_regions",
        "deny_inside_allowed_regions",
      ]
      # european regions inside C5 compliance scope
      allowed_regions = [
        "eu-central-1",
        "eu-central-2", 
        "eu-west-1",
        "eu-west-2",
        "eu-west-3",
        "eu-north-1",
        "eu-south-1",
        "eu-south-2"
      ]
      whitelist_for_other_regions = [
        # allowed global services (C5 compliant)
        "acm:*",
        "budgets:*",
        "ce:*",
        "cloudfront:*",
        "health:*",
        "iam:*",
        "kms:*",
        "organizations:*",
        "route53:*",
        "shield:*",
        "sts:*",
        "support:*",
        "waf:*"
      ]
      whitelist_for_allowed_regions = [
        # only allow services in C5 compliance scope
        # Essential AWS services (always needed)
        "aws-portal:*",
        "budgets:*",
        "ce:*",
        "health:*",
        "iam:*",
        "kms:*",
        "organizations:*",
        "pricing:*",
        "sts:*",
        "support:*",
        "trustedadvisor:*",
        
        # C5 Compliant Services - Compute & Containers
        "ec2:*",
        "ecs:*",
        "eks:*",
        "lambda:*",
        "batch:*",
        "apprunner:*",
        "autoscaling:*",
        "imagebuilder:*",
        "elasticbeanstalk:*",
        
        # C5 Compliant Services - Storage
        "s3:*",
        "elasticfilesystem:*",
        "fsx:*",
        "glacier:*",
        "storagegateway:*",
        "backup:*",
        
        # C5 Compliant Services - Databases
        "rds:*",
        "dynamodb:*",
        "docdb:*",
        "elasticache:*",
        "memorydb:*",
        "neptune:*",
        "redshift:*",
        "timestream:*",
        "qldb:*",
        "cassandra:*",
        
        # C5 Compliant Services - Networking & Content Delivery
        "cloudfront:*",
        "route53:*",
        "directconnect:*",
        "elasticloadbalancing:*",
        "globalaccelerator:*",
        "appmesh:*",
        "servicediscovery:*",
        "apigateway:*",
        
        # C5 Compliant Services - Security, Identity & Compliance
        "sso:*",
        "cloudhsm:*",
        "acm:*",
        "secretsmanager:*",
        "cloudtrail:*",
        "config:*",
        "securityhub:*",
        "guardduty:*",
        "inspector:*",
        "macie:*",
        "shield:*",
        "waf:*",
        "network-firewall:*",
        "fms:*",
        "detective:*",
        "auditmanager:*",
        "artifact:*",
        "acm-pca:*",
        "payment-cryptography:*",
        "signer:*",
        "securitylake:*",
        
        # C5 Compliant Services - Analytics
        "athena:*",
        "elasticmapreduce:*",
        "glue:*",
        "databrew:*",
        "kinesis:*",
        "kinesisvideo:*",
        "firehose:*",
        "es:*",
        "quicksight:*",
        "lakeformation:*",
        "datazone:*",
        "kinesisanalytics:*",
        "kafka:*",
        "dataexchange:*",
        "entityresolution:*",
        "finspace:*",
        
        # C5 Compliant Services - Machine Learning
        "sagemaker:*",
        "comprehend:*",
        "comprehendmedical:*",
        "textract:*",
        "rekognition:*",
        "polly:*",
        "transcribe:*",
        "translate:*",
        "lex:*",
        "personalize:*",
        "forecast:*",
        "frauddetector:*",
        "a2i:*",
        "bedrock:*",
        "qbusiness:*",
        "codewhisperer:*",
        "devops-guru:*",
        "kendra:*",
        "geo:*",
        
        # C5 Compliant Services - Developer Tools
        "codecommit:*",
        "codebuild:*",
        "codedeploy:*",
        "codepipeline:*",
        "cloud9:*",
        "cloudshell:*",
        "xray:*",
        "appsync:*",
        
        # C5 Compliant Services - Management & Governance
        "controltower:*",
        "cloudformation:*",
        "ssm:*",
        "opsworks:*",
        "servicecatalog:*",
        "managedservices:*",
        "license-manager:*",
        "resource-groups:*",
        "ram:*",
        "notifications:*",
        "resiliencehub:*",
        
        # C5 Compliant Services - Migration & Transfer
        "dms:*",
        "datasync:*",
        "mgn:*",
        "drs:*",
        "transfer:*",
        "snowball:*",
        "m2:*",
        
        # C5 Compliant Services - Messaging
        "sqs:*",
        "sns:*",
        "ses:*",
        "chime:*",
        "chatbot:*",
        "connect:*",
        "mobiletargeting:*",
        "workmail:*",
        
        # C5 Compliant Services - Business Applications
        "workspaces:*",
        "workspaces-web:*",
        "workspaces-thin-client:*",
        "workdocs:*",
        "appstream:*",
        "wickr:*",
        
        # C5 Compliant Services - IoT
        "iot:*",
        "iotevents:*",
        "greengrass:*",
        "iotsitewise:*",
        "iottwinmaker:*",
        
        # C5 Compliant Services - Media Services
        "mediaconnect:*",
        "mediaconvert:*",
        "medialive:*",
        
        # C5 Compliant Services - Quantum Computing
        "braket:*",
        
        # C5 Compliant Services - Robotics
        "robomaker:*",
        
        # C5 Compliant Services - Healthcare
        "medical-imaging:*",
        "healthlake:*",
        "omics:*",
        
        # C5 Compliant Services - Integration
        "events:*",
        "states:*",
        "mq:*",
        "appflow:*",
        "swf:*",
        "airflow:*",
        
        # C5 Compliant Services - Containers
        "ecr:*",
        
        # C5 Compliant Services - Serverless
        "serverlessrepo:*",
        
        # C5 Compliant Services - Monitoring
        "cloudwatch:*",
        "logs:*",
        "grafana:*",
        "aps:*",
        
        # C5 Compliant Services - Other Services
        "amplify:*",
        "clouddirectory:*",
        "ds:*",
        "appfabric:*",
        "cleanrooms:*",
        "fis:*",
        "outposts:*",
        "sdb:*",
        "route53-recovery-control-config:*",
        "freertos:*"
      ]
      # NOTE: not even the 'OrganizationAccountAccessRole' is allowed to configure non C5 compliant services
      # exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    }
  ]

  # resource control policies (RCPs) can apply permission guardrails at the resource level
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html
  resource_control_policy_templates = [
    {
      policy_name        = "rcp_enforce_confused_deputy_protection"
      policy_description = "Enforce confused deputy protection for s3, sqs, kms, secretsmanager and sts"
      policy_type        = "RESOURCE_CONTROL_POLICY"
      target_ou_paths    = ["/root"]
      template_names     = ["enforce_confused_deputy_protection"]
      # template specific parameters
      # WARNING: to avoid cyclic dependency do not reference 'module.ntc_organizations.org_id' directly
      # you can use ntc_paramters as a workaround to pass the org_id
      org_id = local.ntc_parameters["mgmt-organizations"]["org_id"]
      # list of service actions supported by RCPs
      # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html#rcp-supported-services
      enforced_service_actions = [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        "sts:*",
      ]
      # add exception for certain resources
      exclude_resource_arns = []
    },
    {
      policy_name        = "rcp_enforce_principal_access_from_organization"
      policy_description = "Enforce principal access from organization for s3, sqs, kms, secretsmanager and sts"
      policy_type        = "RESOURCE_CONTROL_POLICY"
      target_ou_paths    = ["/root"]
      template_names     = ["enforce_principal_access_from_organization"]
      # template specific parameters
      # WARNING: to avoid cyclic dependency do not reference 'module.ntc_organizations.org_id' directly
      # you can use ntc_paramters as a workaround to pass the org_id
      org_id = local.ntc_parameters["mgmt-organizations"]["org_id"]
      # list of service actions supported by RCPs
      # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html#rcp-supported-services
      enforced_service_actions = [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        # WARNING: do not include all sts actions to avoid conflicts with identity center
        "sts:AssumeRole",
        "sts:SetContext",
      ]
      # add exception for certain resources
      exclude_resource_arns = []
      # add exception for certain principals outside your organization
      exclude_principal_arns = []
    },
    {
      policy_name        = "rcp_enforce_secure_transport"
      policy_description = "Enforce secure transport for s3, sqs, kms, secretsmanager and sts"
      policy_type        = "RESOURCE_CONTROL_POLICY"
      target_ou_paths    = ["/root"]
      template_names     = ["enforce_secure_transport"]
      # list of service actions supported by RCPs
      # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html#rcp-supported-services
      enforced_service_actions = [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        "sts:*",
      ]
      # add exception for certain resources
      exclude_resource_arns = []
    },
    {
      policy_name        = "rcp_enforce_s3_encryption_and_tls_version"
      policy_description = "Enforce S3 encryption and TLS version"
      policy_type        = "RESOURCE_CONTROL_POLICY"
      target_ou_paths    = ["/root"]
      template_names = [
        "enforce_s3_kms_encryption",
        "enforce_s3_tls_version"
      ]
      # set the minimum TLS version for access to S3 buckets
      s3_tls_minimum_version = "1.2"
      # add exception for certain resources
      exclude_resource_arns = []
    },
  ]
}
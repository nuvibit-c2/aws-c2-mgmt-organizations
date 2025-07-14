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
      # SCP template names that define the policy logic:
      # - deny_outside_allowed_regions: blocks all actions outside allowed_regions (except whitelist_for_other_regions)
      # - deny_inside_allowed_regions: blocks non-whitelisted actions inside allowed_regions (only allows whitelist_for_allowed_regions)
      template_names = [
        "deny_outside_allowed_regions",
        "deny_inside_allowed_regions",
      ]
      # European regions within C5 compliance scope
      # These are the ONLY regions where C5 compliant services can be deployed
      # All other regions will be blocked by the SCP
      allowed_regions = [
        "eu-central-1", # Frankfurt
        "eu-central-2", # Zürich
        "eu-west-1",    # Ireland
        "eu-west-2",    # London
        "eu-west-3",    # Paris
        "eu-north-1",   # Stockholm
        "eu-south-1",   # Milan
        "eu-south-2",   # Spain
      ]
      # Services allowed to run in regions OUTSIDE of the allowed_regions list
      # These are typically global services that don't have regional endpoints
      # or services that must be accessed globally (like IAM, CloudFront, Route53)
      whitelist_for_other_regions = [
        "acm:*",                     # AWS Certificate Manager
        "budgets:*",                 # AWS Budgets
        "ce:*",                      # AWS Cost Explorer Service
        "cloudfront:*",              # Amazon CloudFront
        "health:*",                  # AWS Health APIs and Notifications
        "iam:*",                     # AWS Identity and Access Management
        "kms:*",                     # AWS Key Management Service
        "organizations:*",           # AWS Organizations
        "route53:*",                 # Amazon Route 53
        "shield:*",                  # AWS Shield
        "sts:*",                     # AWS Security Token Service
        "support:*",                 # AWS Support
        "waf:*"                      # AWS WAF
      ]
      # Services allowed to run WITHIN the allowed_regions list (EU regions for C5 compliance)
      # This is the comprehensive list of ALL C5 compliant services that can be used
      # in the specified European regions
      whitelist_for_allowed_regions = [
        # Essential AWS services
        "aws-portal:*",                # AWS Billing and Cost Management
        "budgets:*",                   # AWS Budgets
        "ce:*",                        # AWS Cost Explorer
        "health:*",                    # AWS Health Dashboard
        "iam:*",                       # AWS Identity and Access Management (IAM)
        "kms:*",                       # AWS Key Management Service
        "organizations:*",             # AWS Organizations
        "pricing:*",                   # AWS Price List API
        "sts:*",                       # AWS Security Token Service (STS)
        "support:*",                   # AWS Support
        "trustedadvisor:*",            # AWS Trusted Advisor

        # Compute & Containers
        "ec2:*",                       # Amazon EC2
        "ecs:*",                       # Amazon ECS
        "eks:*",                       # Amazon EKS
        "lambda:*",                    # AWS Lambda
        "batch:*",                     # AWS Batch
        "apprunner:*",                 # AWS App Runner
        "autoscaling:*",               # Amazon EC2 Auto Scaling
        "imagebuilder:*",              # EC2 Image Builder
        "elasticbeanstalk:*",          # AWS Elastic Beanstalk

        # Storage
        "s3:*",                        # Amazon S3
        "elasticfilesystem:*",         # Amazon EFS
        "fsx:*",                       # Amazon FSx
        "glacier:*",                   # Amazon S3 Glacier
        "storagegateway:*",            # AWS Storage Gateway
        "backup:*",                    # AWS Backup

        # Databases
        "rds:*",                       # Amazon RDS
        "dynamodb:*",                  # Amazon DynamoDB
        "docdb:*",                     # Amazon DocumentDB
        "elasticache:*",               # Amazon ElastiCache
        "memorydb:*",                  # Amazon MemoryDB
        "neptune:*",                   # Amazon Neptune
        "redshift:*",                  # Amazon Redshift
        "timestream:*",                # Amazon Timestream
        "qldb:*",                      # Amazon QLDB
        "cassandra:*",                 # Amazon Keyspaces (for Apache Cassandra)

        # Networking & Content Delivery
        "cloudfront:*",                # Amazon CloudFront
        "route53:*",                   # Amazon Route 53
        "directconnect:*",             # AWS Direct Connect
        "elasticloadbalancing:*",      # Elastic Load Balancing
        "globalaccelerator:*",         # AWS Global Accelerator
        "appmesh:*",                   # AWS App Mesh
        "servicediscovery:*",          # AWS Cloud Map
        "apigateway:*",                # Amazon API Gateway

        # Security, Identity & Compliance
        "sso:*",                       # AWS IAM Identity Center (successor to AWS SSO)
        "cloudhsm:*",                  # AWS CloudHSM
        "acm:*",                       # AWS Certificate Manager
        "secretsmanager:*",            # AWS Secrets Manager
        "cloudtrail:*",                # AWS CloudTrail
        "config:*",                    # AWS Config
        "securityhub:*",               # AWS Security Hub
        "guardduty:*",                 # Amazon GuardDuty
        "inspector2:*",                # Amazon Inspector
        "inspector:*",                 # Amazon Inspector Classic
        "macie:*",                     # Amazon Macie
        "shield:*",                    # AWS Shield
        "waf:*",                       # AWS WAF
        "network-firewall:*",          # AWS Network Firewall
        "fms:*",                       # AWS Firewall Manager
        "detective:*",                 # Amazon Detective
        "auditmanager:*",              # AWS Audit Manager
        "artifact:*",                  # AWS Artifact
        "acm-pca:*",                   # AWS Private CA
        "payment-cryptography:*",      # AWS Payment Cryptography
        "signer:*",                    # AWS Signer
        "securitylake:*",              # Amazon Security Lake

        # Analytics
        "athena:*",                    # Amazon Athena
        "elasticmapreduce:*",          # Amazon EMR
        "glue:*",                      # AWS Glue
        "databrew:*",                  # AWS Glue DataBrew
        "kinesis:*",                   # Amazon Kinesis
        "kinesisvideo:*",              # Amazon Kinesis Video Streams
        "firehose:*",                  # Amazon Kinesis Data Firehose
        "es:*",                        # Amazon OpenSearch Service
        "quicksight:*",                # Amazon QuickSight
        "lakeformation:*",             # AWS Lake Formation
        "datazone:*",                  # Amazon DataZone
        "kinesisanalytics:*",          # Amazon Kinesis Data Analytics
        "kafka:*",                     # Amazon Managed Streaming for Apache Kafka (MSK)
        "dataexchange:*",              # AWS Data Exchange
        "entityresolution:*",          # AWS Entity Resolution
        "finspace:*",                  # Amazon FinSpace

        # Machine Learning
        "sagemaker:*",                 # Amazon SageMaker
        "comprehend:*",                # Amazon Comprehend
        "comprehendmedical:*",         # Amazon Comprehend Medical
        "textract:*",                  # Amazon Textract
        "rekognition:*",               # Amazon Rekognition
        "polly:*",                     # Amazon Polly
        "transcribe:*",                # Amazon Transcribe
        "translate:*",                 # Amazon Translate
        "lex:*",                       # Amazon Lex
        "personalize:*",               # Amazon Personalize
        "forecast:*",                  # Amazon Forecast
        "frauddetector:*",             # Amazon Fraud Detector
        "a2i:*",                       # Amazon Augmented AI (A2I)
        "bedrock:*",                   # Amazon Bedrock
        "qbusiness:*",                 # Amazon Q Business
        "codewhisperer:*",             # Amazon CodeWhisperer
        "devops-guru:*",               # Amazon DevOps Guru
        "kendra:*",                    # Amazon Kendra
        "geo:*",                       # Amazon Location Service

        # Developer Tools
        "codecommit:*",                # AWS CodeCommit
        "codebuild:*",                 # AWS CodeBuild
        "codedeploy:*",                # AWS CodeDeploy
        "codepipeline:*",              # AWS CodePipeline
        "cloud9:*",                    # AWS Cloud9
        "cloudshell:*",                # AWS CloudShell
        "xray:*",                      # AWS X-Ray
        "appsync:*",                   # AWS AppSync

        # Management & Governance
        "controltower:*",              # AWS Control Tower
        "cloudformation:*",            # AWS CloudFormation
        "ssm:*",                       # AWS Systems Manager
        "opsworks:*",                  # AWS OpsWorks
        "servicecatalog:*",            # AWS Service Catalog
        "managedservices:*",           # AWS Managed Services
        "license-manager:*",           # AWS License Manager
        "resource-groups:*",           # AWS Resource Groups
        "ram:*",                       # AWS Resource Access Manager
        "notifications:*",             # AWS User Notifications
        "resiliencehub:*",             # AWS Resilience Hub

        # Migration & Transfer
        "dms:*",                       # AWS Database Migration Service
        "datasync:*",                  # AWS DataSync
        "mgn:*",                       # AWS Application Migration Service
        "drs:*",                       # AWS Elastic Disaster Recovery
        "transfer:*",                  # AWS Transfer Family
        "snowball:*",                  # AWS Snowball
        "m2:*",                        # AWS Mainframe Modernization (M2)

        # Messaging
        "sqs:*",                       # Amazon SQS
        "sns:*",                       # Amazon SNS
        "ses:*",                       # Amazon SES
        "chime:*",                     # Amazon Chime
        "chatbot:*",                   # AWS Chatbot
        "connect:*",                   # Amazon Connect
        "mobiletargeting:*",           # Amazon Pinpoint
        "workmail:*",                  # Amazon WorkMail

        # Business Applications
        "workspaces:*",                # Amazon WorkSpaces
        "workspaces-web:*",            # Amazon WorkSpaces Web
        "thinclient:*",                # Amazon WorkSpaces Thin Client
        "workdocs:*",                  # Amazon WorkDocs
        "appstream:*",                 # Amazon AppStream 2.0
        "wickr:*",                     # Amazon Wickr

        # IoT
        "iot:*",                       # AWS IoT Core
        "iotevents:*",                 # AWS IoT Events
        "greengrass:*",                # AWS IoT Greengrass
        "iotsitewise:*",               # AWS IoT SiteWise
        "iottwinmaker:*",              # AWS IoT TwinMaker

        # Media Services
        "mediaconnect:*",              # AWS Elemental MediaConnect
        "mediaconvert:*",              # AWS Elemental MediaConvert
        "medialive:*",                 # AWS Elemental MediaLive

        # Quantum Computing
        "braket:*",                    # Amazon Braket

        # Robotics
        "robomaker:*",                 # AWS RoboMaker

        # Healthcare
        "medical-imaging:*",           # AWS HealthImaging
        "healthlake:*",                # Amazon HealthLake
        "omics:*",                     # AWS Omics

        # Integration
        "events:*",                    # Amazon EventBridge
        "states:*",                    # AWS Step Functions
        "mq:*",                        # Amazon MQ
        "appflow:*",                   # Amazon AppFlow
        "swf:*",                       # Amazon SWF
        "airflow:*",                   # Amazon Managed Workflows for Apache Airflow (MWAA)

        # Containers
        "ecr:*",                       # Amazon Elastic Container Registry (ECR)

        # Serverless
        "serverlessrepo:*",            # AWS Serverless Application Repository

        # Monitoring
        "cloudwatch:*",                # Amazon CloudWatch
        "logs:*",                      # Amazon CloudWatch Logs
        "grafana:*",                   # Amazon Managed Grafana
        "aps:*",                       # Amazon Managed Service for Prometheus

        # Other
        "amplify:*",                   # AWS Amplify
        "clouddirectory:*",            # Amazon Cloud Directory
        "ds:*",                        # AWS Directory Service
        "appfabric:*",                 # Amazon AppFabric
        "cleanrooms:*",                # AWS Clean Rooms
        "fis:*",                       # AWS Fault Injection Simulator
        "outposts:*",                  # AWS Outposts
        "sdb:*",                       # Amazon SimpleDB
        "freertos:*",                  # FreeRTOS
      ]

      exclude_principal_arns = []
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
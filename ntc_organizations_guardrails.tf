# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC GUARDRAIL TEMPLATES
# ---------------------------------------------------------------------------------------------------------------------
# This module manages AWS Organizations Service Control Policies (SCPs) and Resource Control Policies (RCPs)
# to enforce security and compliance guardrails across your AWS organization.
#
# IMPORTANT CONCEPTS:
# -------------------
# Service Control Policies (SCPs):
#   - Define maximum permissions for accounts in your organization
#   - Act as permission boundaries - they never grant permissions, only limit them
#   - Applied at organization root, OU, or account level
#   - Affect all IAM users and roles in member accounts (including root user)
#   - Do NOT affect service-linked roles or AWS Organizations management account
#   - Multiple SCPs are combined with logical AND (all must allow the action)
#
# Resource Control Policies (RCPs):
#   - Set maximum permissions for resources in your organization
#   - Control what can be done TO a resource (complementary to SCPs which control what principals CAN DO)
#   - Applied at organization root, OU, or account level
#   - Evaluated alongside IAM policies and SCPs
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_guardrail_templates" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-guardrail-templates?ref=2.2.0"

  # ===================================================================================================================
  # SERVICE CONTROL POLICIES (SCPs)
  # ===================================================================================================================
  # SCPs define the maximum permissions for accounts in your organization.
  # They never grant permissions - they only limit what IAM policies can grant.
  # ===================================================================================================================
  service_control_policy_templates = [
    # -----------------------------------------------------------------------------------------------------------------
    # SCP 1: Root OU Security Baseline
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Enforce fundamental security controls across all accounts in the organization
    # 
    # TEMPLATES USED:
    #   1. deny_leaving_organizations: Prevents accounts from leaving the organization
    #   2. deny_actions_as_root_except_centralized_root: Blocks root user actions except for specific tasks
    #   3. deny_iam_user_and_access_key_creation: Prevents creation of IAM users and long-term access keys
    #   4. deny_login_profile_creation: Prevents console passwords for IAM users (create/update login profile,
    #      change password, update account password policy)
    #
    # SCOPE: Applied to the entire organization (/root)
    #
    # EXCLUSIONS:
    #   - OrganizationAccountAccessRole: Excluded to allow centralized management via this role
    #
    # USE CASE: Baseline security for all accounts to prevent unauthorized changes and enforce
    #           identity federation (no IAM users with long-term credentials or console passwords)
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "scp_root_ou"
      policy_description = "Deny member accounts from leaving the organization, any root user actions except for centralized root privilege tasks and IAM user credentials"
      target_ou_paths    = ["/root"]
      template_names = [
        "deny_leaving_organizations",
        "deny_actions_as_root_except_centralized_root",
        "deny_iam_user_and_access_key_creation",
        "deny_login_profile_creation",
      ]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    # -----------------------------------------------------------------------------------------------------------------
    # SCP 1b: Protected Resources (tag-based)
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Prevent deletion or modification of critical resources which are tagged as protected
    #
    # TEMPLATES USED:
    #   - deny_actions_on_tagged_resources: Denies the listed actions on resources where aws:ResourceTag/<tag_key>
    #     matches one of the tag_values
    #
    # SCOPE: Applied to the entire organization (/root)
    #
    # CONFIGURATION PARAMETERS:
    #   - tagged_resource_actions: Actions denied on protected resources
    #   - tag_key / tag_values: Tag which marks a resource as protected
    #
    # EXCLUSIONS:
    #   - OrganizationAccountAccessRole: Used by the account baseline pipelines (assumed for all member account
    #     actions), so baseline-managed resources can still be updated and destroyed when tagged as protected
    #
    # IMPORTANT:
    #   - Only works for actions which support resource-level permissions and the aws:ResourceTag condition key
    #   - Always include the tagging actions of each protected service, otherwise the protection tag can be
    #     removed first and the resource deleted afterwards
    #   - S3: aws:ResourceTag is only evaluated once ABAC is enabled on the bucket (aws_s3_bucket_abac).
    #     With ABAC enabled, bucket tagging moves from s3:PutBucketTagging to s3:TagResource / s3:UntagResource,
    #     so both pairs are listed to cover buckets before and after enabling ABAC
    #   - Other pipelines which manage protected resources with their own role (i.e. not via
    #     OrganizationAccountAccessRole) must be added to exclude_principal_arns
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "scp_protected_resources"
      policy_description = "Deny deletion and modification actions, and removal of the protection tag, on resources tagged as protected"
      target_ou_paths    = ["/root"]
      template_names     = ["deny_actions_on_tagged_resources"]
      tagged_resource_actions = [
        # ec2 / vpc
        "ec2:TerminateInstances",
        "ec2:DeleteVpc",
        "ec2:DeleteSubnet",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteRouteTable",
        "ec2:DeleteInternetGateway",
        "ec2:DeleteNatGateway",
        "ec2:DeleteTransitGateway",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        # rds
        "rds:DeleteDBInstance",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource",
        # s3 (requires ABAC on the bucket, see note above)
        "s3:DeleteBucket",
        "s3:PutBucketTagging",
        "s3:TagResource",
        "s3:UntagResource",
        # kms (e.g. keys used for tfstate or backup encryption)
        "kms:ScheduleKeyDeletion",
        "kms:DisableKey",
        "kms:PutKeyPolicy",
        "kms:TagResource",
        "kms:UntagResource",
        # iam roles (e.g. account baseline, backup, aws config roles)
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:DetachRolePolicy",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:UpdateAssumeRolePolicy",
        "iam:UpdateRole",
        "iam:UpdateRoleDescription",
        "iam:PutRolePermissionsBoundary",
        "iam:TagRole",
        "iam:UntagRole",
        # iam oidc identity providers (e.g. github actions / spacelift oidc federation)
        "iam:DeleteOpenIDConnectProvider",
        "iam:UpdateOpenIDConnectProviderThumbprint",
        "iam:AddClientIDToOpenIDConnectProvider",
        "iam:RemoveClientIDFromOpenIDConnectProvider",
        "iam:TagOpenIDConnectProvider",
        "iam:UntagOpenIDConnectProvider",
        # aws backup vault
        "backup:DeleteBackupVault",
        "backup:DeleteBackupVaultAccessPolicy",
        "backup:DeleteBackupVaultLockConfiguration",
        "backup:PutBackupVaultAccessPolicy",
        "backup:PutBackupVaultLockConfiguration",
        "backup:TagResource",
        "backup:UntagResource",
      ]
      tag_key                = "ManagedBy"
      tag_values             = ["ntc-account-factory"]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    # -----------------------------------------------------------------------------------------------------------------
    # SCP 1c: Blacklisted Services
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Deny specific AWS services organization-wide (lighter alternative to full service whitelisting)
    #
    # TEMPLATES USED:
    #   - deny_blacklisted_services: Denies all actions listed in blacklisted_services
    #
    # SCOPE: Applied to the entire organization (/root)
    #
    # CONFIGURATION PARAMETERS:
    #   - blacklisted_services: Actions to deny, as "service:*" or specific actions
    #
    # EXCLUSIONS:
    #   - OrganizationAccountAccessRole: Allows organization admins to clean up existing resources
    #
    # USE CASE: Block services which bypass central controls or are not approved for use
    #
    # NOTE: Deny wins over any whitelist, so a blacklisted service stays blocked even if it is listed in
    #       whitelist_for_allowed_regions or whitelist_for_specific_regions of another SCP
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "scp_blacklisted_services"
      policy_description = "Deny usage of blacklisted services"
      target_ou_paths    = ["/root"]
      template_names     = ["deny_blacklisted_services"]
      blacklisted_services = [
        "lightsail:*", # bypasses VPC, network firewall and central networking controls
        "gamelift:*",  # no business use case
      ]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    # -----------------------------------------------------------------------------------------------------------------
    # SCP 2: Suspended/Transitional Accounts Lock-down
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Completely disable all AWS service access for suspended or transitional accounts
    # 
    # TEMPLATES USED:
    #   - deny_all: Blocks all AWS service actions
    #
    # SCOPE: Applied to suspended and transitional OUs
    #
    # EXCLUSIONS:
    #   - OrganizationAccountAccessRole: Allows organization admins to manage these accounts
    #
    # USE CASE: 
    #   - Suspended accounts: Security incident response, billing issues, compliance violations
    #   - Transitional accounts: Accounts being migrated, decommissioned, or under review
    #
    # CONFIGURATION TIP: Move accounts to these OUs when they need to be temporarily disabled
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "scp_suspended_ou"
      policy_description = "Deny all actions for suspended accounts"
      target_ou_paths = [
        "/root/suspended",
        "/root/transitional"
      ]
      template_names         = ["deny_all"]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    # -----------------------------------------------------------------------------------------------------------------
    # SCP 3: Regional Restriction for Workload Accounts
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Enforce data residency and regional compliance by restricting AWS service usage to specific regions
    # 
    # TEMPLATES USED:
    #   - deny_outside_allowed_regions: Blocks actions outside specified regions (except whitelisted global services)
    #
    # SCOPE: Applied to workload accounts (/root/workloads)
    #
    # CONFIGURATION PARAMETERS:
    #   - allowed_regions: Define which AWS regions workloads can be deployed to
    #   - whitelist_for_other_regions: Harmless, region-agnostic actions accessible from ANY region
    #     (e.g., ec2:DescribeRegions for cross-region automation)
    #   - whitelist_for_specific_regions: Regions which are partially opened for specific actions
    #     (e.g., global services like IAM, CloudFront, Route53, STS in us-east-1, Lambda@Edge in us-east-1)
    #
    # EXCLUSIONS:
    #   - OrganizationAccountAccessRole: Allows cross-region management access
    #
    # USE CASE: Enforce data residency requirements (e.g., GDPR requiring data in EU regions)
    #
    # CONFIGURATION TIP:
    #   - Add regions to allowed_regions for data residency requirements
    #   - Global services pin their API calls to a specific region (mostly us-east-1, some us-west-2), so map
    #     them in whitelist_for_specific_regions instead of whitelisting them in every region
    #   - Overriding whitelist_for_specific_regions replaces the module default, so keep the default entries
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "scp_workloads_ou"
      policy_description = "Deny all actions outside allowed regions except global services"
      target_ou_paths    = ["/root/workloads"]
      template_names     = ["deny_outside_allowed_regions"]
      allowed_regions = [
        "eu-central-1",
        "eu-central-2",
      ]
      # Harmless, region-agnostic actions which can be called from ANY region
      # e.g. a central networking account enumerating transit gateways across all regions
      whitelist_for_other_regions = [
        "ec2:DescribeRegions",
        "ec2:DescribeTransitGateways",
        "ec2:DescribeVpnGateways",
      ]
      # Regions which are partially opened for specific actions (in addition to allowed_regions)
      # In each region ONLY the listed actions are allowed, everything else stays denied.
      # NOTE: this overrides the module default - the default global service entries are repeated here
      whitelist_for_specific_regions = {
        # -------------------------------------------------------------------------------------------------------------
        # EXCEPTIONS FOR SERVICES RUNNING IN OTHER REGIONS
        # -------------------------------------------------------------------------------------------------------------
        # Global services pin their control plane to a specific region, regardless of the region the caller's
        # SDK/CLI is configured for. Some services may also legitimately need to operate in specific regions
        # outside the allowed_regions list. Common use cases for regional exceptions:
        #
        # 1. LAMBDA@EDGE (CloudFront Functions):
        #    - CloudFront is a global service but Lambda@Edge functions must be deployed in us-east-1
        #    - Required for: Request/response manipulation, A/B testing, security headers
        #    - Add: "lambda:*" or specific Lambda@Edge actions to "us-east-1"
        #
        # 2. DISASTER RECOVERY / BUSINESS CONTINUITY:
        #    - Backup regions outside primary data residency requirements
        #    - Required for: RTO/RPO compliance, resilience, failover capabilities
        #    - Add: Service-specific actions to the DR region (e.g., "us-west-2" = ["s3:*", "dynamodb:*"])
        #
        # 3. THIRD-PARTY INTEGRATIONS:
        #    - SaaS vendors requiring specific regions (e.g., us-east-1, us-west-2)
        #    - Required for: VPC endpoints, PrivateLink, data exchange
        #    - Add: Service actions for specific integrations to the vendor's region
        #
        # CONFIGURATION GUIDELINES:
        #   ✓ Document WHY each service needs regional exceptions
        #   ✓ Use specific actions (e.g., "lambda:InvokeFunction") instead of wildcards when possible
        #   ✓ An action can be listed for multiple regions, patterns may overlap across regions
        #     (e.g., "lambda:*" in us-east-1 and "lambda:Get*" in eu-west-1)
        #   ✓ Regularly review and remove unused exceptions
        #   ✓ Consider data residency and compliance implications
        #   ✓ Validate exceptions with security and compliance teams
        #
        # SECURITY CONSIDERATIONS:
        #   ⚠️  Exceptions bypass regional data residency controls for the listed actions in the listed regions
        #   ⚠️  Ensure no sensitive data is processed in excepted regions
        #   ⚠️  Monitor CloudTrail for unexpected cross-region activity
        #   ⚠️  Use resource-based policies to further restrict access
        # -------------------------------------------------------------------------------------------------------------
        "us-east-1" = [
          "a4b:*",
          "account:Get*",
          "account:List*",
          "acm:*",
          "aws-marketplace-management:*",
          "aws-marketplace:*",
          "aws-portal:*",
          "bcm-dashboards:*", # c1 addition: Billing and Cost Management dashboards
          "billing:*",
          "billingconductor:*",
          "budgets:*",
          "ce:*",
          "chime:*",
          "cloudfront:*",
          "config:*",
          "consolidatedbilling:*",
          "cost-optimization-hub:*",
          "cur:*",
          "directconnect:*",
          "ecr-public:GetAuthorizationToken",
          "fms:*",
          "freetier:*",
          "health:*",
          "iam:*",
          "importexport:*",
          "invoicing:*",
          "kms:*",
          "lambda:*", # c1 addition: Lambda@Edge functions for CloudFront (requires us-east-1)
          "mobileanalytics:*",
          "notifications-contacts:*",
          "notifications:*",
          "organizations:*",
          "payments:*",
          "pricing:*",
          "route53:*",
          "route53domains:*",
          "s3:GetAccountPublic*",
          "s3:ListAllMyBuckets",
          "s3:PutAccountPublic*",
          "savingsplans:*",
          "shield:*",
          "sts:*",
          "support:*",
          "supportplans:*",
          "tax:*",
          "trustedadvisor:*",
          "waf-regional:*",
          "waf:*",
          "wafv2:*",
          "wellarchitected:*",
        ]
        # globalaccelerator, networkmanager, route53-recovery-* and s3 multi-region access points use us-west-2
        "us-west-2" = [
          "globalaccelerator:*",
          "networkmanager:*",
          "route53-recovery-cluster:*",
          "route53-recovery-control-config:*",
          "route53-recovery-readiness:*",
          "s3:CreateMultiRegionAccessPoint",
          "s3:DeleteMultiRegionAccessPoint",
          "s3:DescribeMultiRegionAccessPointOperation",
          "s3:GetMultiRegionAccessPoint",
          "s3:GetMultiRegionAccessPointPolicy",
          "s3:GetMultiRegionAccessPointPolicyStatus",
          "s3:ListMultiRegionAccessPoints",
          "s3:PutMultiRegionAccessPointPolicy",
        ]
      }
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
      # exclude bedrock inference profiles in denied regions to avoid issues with cross region inference
      # https://docs.aws.amazon.com/bedrock/latest/userguide/global-cross-region-inference.html
      exclude_bedrock_inference_profile_arns = ["arn:aws:bedrock:*:*:inference-profile/eu.*"]
    },
    # -----------------------------------------------------------------------------------------------------------------
    # SCP 4: Service Whitelisting with Regional Restrictions
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Implement defense-in-depth by combining regional restrictions with service whitelisting
    # 
    # TEMPLATES USED:
    #   1. deny_outside_allowed_regions: Blocks actions outside specified regions
    #   2. deny_inside_allowed_regions: Blocks all services EXCEPT those explicitly whitelisted
    #
    # SCOPE: Can be applied to workload OUs for strict control
    #
    # CONFIGURATION PARAMETERS:
    #   - allowed_regions: Regions where services can operate
    #   - whitelist_for_other_regions / whitelist_for_specific_regions: module defaults are used (see SCP 3)
    #   - whitelist_for_allowed_regions: Services permitted within allowed regions
    #
    # USE CASE: High-security environments requiring explicit approval for each AWS service
    #
    # IMPLEMENTATION STRATEGY:
    #   1. Start with a minimal whitelist (compute, storage, networking basics)
    #   2. Add services as teams request and justify them
    #   3. Document why each service is whitelisted
    #   4. Regularly review and remove unused services
    #
    # WARNING: This creates a deny-by-default posture. Carefully test before deploying to production.
    #          Comment out this policy initially and enable only after validating service requirements.
    #
    # CONFIGURATION TIP:
    #   - Use wildcards (e.g., "ec2:*") for broad service access
    #   - Use specific actions (e.g., "s3:GetObject") for granular control
    #   - Coordinate with application teams to identify required services before deployment
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "scp_workloads_ou_whitelisting"
      policy_description = "Deny all actions except whitelisted services"
      target_ou_paths    = ["/root/workloads"]
      template_names = [
        "deny_outside_allowed_regions",
        "deny_inside_allowed_regions",
      ]
      allowed_regions = [
        "eu-central-1",
        "eu-central-2",
        "eu-west-1",
        "us-east-1",
      ]
      # whitelist_for_other_regions and whitelist_for_specific_regions are not set, so the module defaults apply:
      #   - whitelist_for_other_regions: harmless ec2 describe actions accessible from any region
      #   - whitelist_for_specific_regions: global services in us-east-1 and us-west-2
      # us-east-1 is already in allowed_regions, so only the us-west-2 entries have an effect here
      # Regional services permitted within allowed_regions
      # CONFIGURATION STRATEGY:
      #   - Start with essential services your teams need
      #   - Add "service:*" for full service access or "service:SpecificAction" for granular control
      #   - Document business justification for each service
      #   - Review quarterly and remove unused services
      whitelist_for_allowed_regions = [
        "a4b:*",
        "acm:*",
        "aws-marketplace-management:*",
        "aws-marketplace:*",
        "aws-portal:*",
        "budgets:*",
        "ce:*",
        "chime:*",
        "cloudfront:*",
        "cloudwatch:*",
        "logs:*",
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
        "ec2:*",
      ]
      # Principals exempt from this SCP (typically management roles)
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
      # exclude bedrock inference profiles in denied regions to avoid issues with cross region inference
      # https://docs.aws.amazon.com/bedrock/latest/userguide/global-cross-region-inference.html
      exclude_bedrock_inference_profile_arns = ["arn:aws:bedrock:*:*:inference-profile/eu.*"]
    },
    # -----------------------------------------------------------------------------------------------------------------
    # SCP 5: BSI C5 Compliance Framework
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Enforce German Federal Office for Information Security (BSI) Cloud Computing Compliance 
    #          Controls Catalogue (C5) by restricting services to C5-certified AWS services in EU regions
    # 
    # TEMPLATES USED:
    #   1. deny_outside_allowed_regions: Restricts to EU regions only
    #   2. deny_inside_allowed_regions: Permits only C5-compliant services
    #
    # SCOPE: Can be applied to workload OUs for strict control
    #
    # COMPLIANCE FRAMEWORK:
    #   - BSI C5 Type 2 Attestation required for German government and regulated industries
    #   - Services listed are C5-certified as of the last AWS compliance update
    #   - Reference: https://aws.amazon.com/compliance/bsi-c5/
    #   - Service scope: https://aws.amazon.com/compliance/services-in-scope/C5/
    #
    # CONFIGURATION PARAMETERS:
    #   - allowed_regions: EU regions with C5 certification
    #   - whitelist_for_specific_regions: C5-compliant global services (us-east-1 only)
    #   - whitelist_for_allowed_regions: C5-compliant regional services
    #
    # DEPLOYMENT STRATEGY:
    #   1. Deploy to sandbox/dev OU first for testing
    #   2. Work with application teams to validate service requirements
    #   3. Gradually roll out to production OUs
    #   4. Update service list when AWS publishes new C5 certifications
    #
    # MAINTENANCE:
    #   - Review AWS C5 compliance page quarterly for newly certified services
    #   - Test new services in sandbox before adding to production policy
    #   - Document any exceptions with business justification
    #
    # WARNING: Restricting to C5-compliant services may limit some AWS features.
    #          Thoroughly test application compatibility before production deployment.
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "scp_workloads_ou_c5_compliance"
      policy_description = "Allow only C5 compliant services in EU regions"
      target_ou_paths    = ["/root/workloads"]
      template_names = [
        "deny_outside_allowed_regions",
        "deny_inside_allowed_regions",
      ]
      # EU regions with BSI C5 Type 2 Attestation
      # CONFIGURATION: Only these regions are permitted for C5-compliant workloads
      # IMPORTANT: Verify current C5 certification status before adding/removing regions
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
      # No actions are exempted in every region
      whitelist_for_other_regions = []
      # C5-compliant global services (only accessible in us-east-1, where their control plane is located)
      # These services are certified under BSI C5 and provide global endpoints
      # MAINTENANCE: Update when AWS publishes new C5 certifications
      whitelist_for_specific_regions = {
        "us-east-1" = [
          "acm:*",           # AWS Certificate Manager
          "budgets:*",       # AWS Budgets
          "ce:*",            # AWS Cost Explorer Service
          "cloudfront:*",    # Amazon CloudFront
          "health:*",        # AWS Health APIs and Notifications
          "iam:*",           # AWS Identity and Access Management
          "kms:*",           # AWS Key Management Service
          "organizations:*", # AWS Organizations
          "route53:*",       # Amazon Route 53
          "shield:*",        # AWS Shield
          "sts:*",           # AWS Security Token Service
          "support:*",       # AWS Support
          "waf:*",           # AWS WAF
        ]
      }
      # C5-compliant regional services (accessible within allowed EU regions)
      # This comprehensive list includes all AWS services certified under BSI C5
      # Services are organized by category for easier maintenance
      # 
      # MAINTENANCE INSTRUCTIONS:
      #   1. Check https://aws.amazon.com/compliance/services-in-scope/C5/ quarterly
      #   2. Add newly certified services with format: "service:*"  # Service Name
      #   3. Test in sandbox before deploying to production
      #   4. Remove deprecated services after validating they're no longer in use
      #   5. Keep services alphabetically ordered within each category
      whitelist_for_allowed_regions = [
        # Essential AWS services
        "aws-portal:*",     # AWS Billing and Cost Management
        "budgets:*",        # AWS Budgets
        "ce:*",             # AWS Cost Explorer
        "health:*",         # AWS Health Dashboard
        "iam:*",            # AWS Identity and Access Management (IAM)
        "kms:*",            # AWS Key Management Service
        "organizations:*",  # AWS Organizations
        "pricing:*",        # AWS Price List API
        "sts:*",            # AWS Security Token Service (STS)
        "support:*",        # AWS Support
        "trustedadvisor:*", # AWS Trusted Advisor

        # Compute & Containers
        "ec2:*",              # Amazon EC2
        "ecs:*",              # Amazon ECS
        "eks:*",              # Amazon EKS
        "lambda:*",           # AWS Lambda
        "batch:*",            # AWS Batch
        "apprunner:*",        # AWS App Runner
        "autoscaling:*",      # Amazon EC2 Auto Scaling
        "imagebuilder:*",     # EC2 Image Builder
        "elasticbeanstalk:*", # AWS Elastic Beanstalk

        # Storage
        "s3:*",                # Amazon S3
        "elasticfilesystem:*", # Amazon EFS
        "fsx:*",               # Amazon FSx
        "glacier:*",           # Amazon S3 Glacier
        "storagegateway:*",    # AWS Storage Gateway
        "backup:*",            # AWS Backup

        # Databases
        "rds:*",         # Amazon RDS
        "dynamodb:*",    # Amazon DynamoDB
        "docdb:*",       # Amazon DocumentDB
        "elasticache:*", # Amazon ElastiCache
        "memorydb:*",    # Amazon MemoryDB
        "neptune:*",     # Amazon Neptune
        "redshift:*",    # Amazon Redshift
        "timestream:*",  # Amazon Timestream
        "qldb:*",        # Amazon QLDB
        "cassandra:*",   # Amazon Keyspaces (for Apache Cassandra)

        # Networking & Content Delivery
        "cloudfront:*",           # Amazon CloudFront
        "route53:*",              # Amazon Route 53
        "directconnect:*",        # AWS Direct Connect
        "elasticloadbalancing:*", # Elastic Load Balancing
        "globalaccelerator:*",    # AWS Global Accelerator
        "appmesh:*",              # AWS App Mesh
        "servicediscovery:*",     # AWS Cloud Map
        "apigateway:*",           # Amazon API Gateway

        # Security, Identity & Compliance
        "sso:*",                  # AWS IAM Identity Center (successor to AWS SSO)
        "cloudhsm:*",             # AWS CloudHSM
        "acm:*",                  # AWS Certificate Manager
        "secretsmanager:*",       # AWS Secrets Manager
        "cloudtrail:*",           # AWS CloudTrail
        "config:*",               # AWS Config
        "securityhub:*",          # AWS Security Hub
        "guardduty:*",            # Amazon GuardDuty
        "inspector2:*",           # Amazon Inspector
        "inspector:*",            # Amazon Inspector Classic
        "macie:*",                # Amazon Macie
        "shield:*",               # AWS Shield
        "waf:*",                  # AWS WAF
        "network-firewall:*",     # AWS Network Firewall
        "fms:*",                  # AWS Firewall Manager
        "detective:*",            # Amazon Detective
        "auditmanager:*",         # AWS Audit Manager
        "artifact:*",             # AWS Artifact
        "acm-pca:*",              # AWS Private CA
        "payment-cryptography:*", # AWS Payment Cryptography
        "signer:*",               # AWS Signer
        "securitylake:*",         # Amazon Security Lake

        # Analytics
        "athena:*",           # Amazon Athena
        "elasticmapreduce:*", # Amazon EMR
        "glue:*",             # AWS Glue
        "databrew:*",         # AWS Glue DataBrew
        "kinesis:*",          # Amazon Kinesis
        "kinesisvideo:*",     # Amazon Kinesis Video Streams
        "firehose:*",         # Amazon Kinesis Data Firehose
        "es:*",               # Amazon OpenSearch Service
        "quicksight:*",       # Amazon QuickSight
        "lakeformation:*",    # AWS Lake Formation
        "datazone:*",         # Amazon DataZone
        "kinesisanalytics:*", # Amazon Kinesis Data Analytics
        "kafka:*",            # Amazon Managed Streaming for Apache Kafka (MSK)
        "dataexchange:*",     # AWS Data Exchange
        "entityresolution:*", # AWS Entity Resolution
        "finspace:*",         # Amazon FinSpace

        # Machine Learning
        "sagemaker:*",         # Amazon SageMaker
        "comprehend:*",        # Amazon Comprehend
        "comprehendmedical:*", # Amazon Comprehend Medical
        "textract:*",          # Amazon Textract
        "rekognition:*",       # Amazon Rekognition
        "polly:*",             # Amazon Polly
        "transcribe:*",        # Amazon Transcribe
        "translate:*",         # Amazon Translate
        "lex:*",               # Amazon Lex
        "personalize:*",       # Amazon Personalize
        "forecast:*",          # Amazon Forecast
        "frauddetector:*",     # Amazon Fraud Detector
        "a2i:*",               # Amazon Augmented AI (A2I)
        "bedrock:*",           # Amazon Bedrock
        "qbusiness:*",         # Amazon Q Business
        "codewhisperer:*",     # Amazon CodeWhisperer
        "devops-guru:*",       # Amazon DevOps Guru
        "kendra:*",            # Amazon Kendra
        "geo:*",               # Amazon Location Service

        # Developer Tools
        "codecommit:*",   # AWS CodeCommit
        "codebuild:*",    # AWS CodeBuild
        "codedeploy:*",   # AWS CodeDeploy
        "codepipeline:*", # AWS CodePipeline
        "cloud9:*",       # AWS Cloud9
        "cloudshell:*",   # AWS CloudShell
        "xray:*",         # AWS X-Ray
        "appsync:*",      # AWS AppSync

        # Management & Governance
        "controltower:*",    # AWS Control Tower
        "cloudformation:*",  # AWS CloudFormation
        "ssm:*",             # AWS Systems Manager
        "opsworks:*",        # AWS OpsWorks
        "servicecatalog:*",  # AWS Service Catalog
        "managedservices:*", # AWS Managed Services
        "license-manager:*", # AWS License Manager
        "resource-groups:*", # AWS Resource Groups
        "ram:*",             # AWS Resource Access Manager
        "notifications:*",   # AWS User Notifications
        "resiliencehub:*",   # AWS Resilience Hub

        # Migration & Transfer
        "dms:*",      # AWS Database Migration Service
        "datasync:*", # AWS DataSync
        "mgn:*",      # AWS Application Migration Service
        "drs:*",      # AWS Elastic Disaster Recovery
        "transfer:*", # AWS Transfer Family
        "snowball:*", # AWS Snowball
        "m2:*",       # AWS Mainframe Modernization (M2)

        # Messaging
        "sqs:*",             # Amazon SQS
        "sns:*",             # Amazon SNS
        "ses:*",             # Amazon SES
        "chime:*",           # Amazon Chime
        "chatbot:*",         # AWS Chatbot
        "connect:*",         # Amazon Connect
        "mobiletargeting:*", # Amazon Pinpoint
        "workmail:*",        # Amazon WorkMail

        # Business Applications
        "workspaces:*",     # Amazon WorkSpaces
        "workspaces-web:*", # Amazon WorkSpaces Web
        "thinclient:*",     # Amazon WorkSpaces Thin Client
        "workdocs:*",       # Amazon WorkDocs
        "appstream:*",      # Amazon AppStream 2.0
        "wickr:*",          # Amazon Wickr

        # IoT
        "iot:*",          # AWS IoT Core
        "iotevents:*",    # AWS IoT Events
        "greengrass:*",   # AWS IoT Greengrass
        "iotsitewise:*",  # AWS IoT SiteWise
        "iottwinmaker:*", # AWS IoT TwinMaker

        # Media Services
        "mediaconnect:*", # AWS Elemental MediaConnect
        "mediaconvert:*", # AWS Elemental MediaConvert
        "medialive:*",    # AWS Elemental MediaLive

        # Quantum Computing
        "braket:*", # Amazon Braket

        # Robotics
        "robomaker:*", # AWS RoboMaker

        # Healthcare
        "medical-imaging:*", # AWS HealthImaging
        "healthlake:*",      # Amazon HealthLake
        "omics:*",           # AWS Omics

        # Integration
        "events:*",  # Amazon EventBridge
        "states:*",  # AWS Step Functions
        "mq:*",      # Amazon MQ
        "appflow:*", # Amazon AppFlow
        "swf:*",     # Amazon SWF
        "airflow:*", # Amazon Managed Workflows for Apache Airflow (MWAA)

        # Containers
        "ecr:*", # Amazon Elastic Container Registry (ECR)

        # Serverless
        "serverlessrepo:*", # AWS Serverless Application Repository

        # Monitoring
        "cloudwatch:*", # Amazon CloudWatch
        "logs:*",       # Amazon CloudWatch Logs
        "grafana:*",    # Amazon Managed Grafana
        "aps:*",        # Amazon Managed Service for Prometheus

        # Other
        "amplify:*",        # AWS Amplify
        "clouddirectory:*", # Amazon Cloud Directory
        "ds:*",             # AWS Directory Service
        "appfabric:*",      # Amazon AppFabric
        "cleanrooms:*",     # AWS Clean Rooms
        "fis:*",            # AWS Fault Injection Simulator
        "outposts:*",       # AWS Outposts
        "sdb:*",            # Amazon SimpleDB
        "freertos:*",       # FreeRTOS
      ]

      # No principal exclusions for C5 compliance - policy applies to all principals
      # CONFIGURATION: Add exclusions only if absolutely necessary for operational reasons
      exclude_principal_arns = []
    }
  ]

  # ===================================================================================================================
  # RESOURCE CONTROL POLICIES (RCPs)
  # ===================================================================================================================
  # RCPs set maximum permissions for RESOURCES (what can be done TO a resource)
  # They complement SCPs which control what principals CAN DO
  # 
  # KEY DIFFERENCES FROM SCPs:
  #   - SCPs: Control what IAM principals can do (identity-based)
  #   - RCPs: Control what can be done to resources (resource-based)
  #   - RCPs are evaluated alongside resource-based policies and SCPs
  #
  # SUPPORTED SERVICES (as of 2024):
  #   - Amazon S3
  #   - Amazon SQS
  #   - AWS KMS
  #   - AWS Secrets Manager
  #   - AWS STS
  #
  # USE CASES:
  #   - Prevent data exfiltration via resource policies
  #   - Enforce encryption requirements
  #   - Require secure transport (HTTPS/TLS)
  #   - Implement confused deputy protection
  #   - Restrict cross-account access
  # ===================================================================================================================
  resource_control_policy_templates = [
    # -----------------------------------------------------------------------------------------------------------------
    # RCP 1: Confused Deputy Protection
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Prevent the "confused deputy" attack where an AWS service is tricked into performing
    #          unauthorized actions on your resources using its credentials
    # 
    # TEMPLATE USED:
    #   - enforce_confused_deputy_protection: Requires aws:SourceAccount or aws:SourceArn conditions
    #
    # SCOPE: Applied organization-wide (/root)
    #
    # ATTACK SCENARIO:
    #   Without this protection, an attacker could create a resource policy that allows an AWS service
    #   to access your resources, then trick that service into accessing them on the attacker's behalf.
    #
    # PROTECTION MECHANISM:
    #   Requires resource-based policies to include aws:SourceAccount or aws:SourceArn conditions
    #   when granting access to AWS services. This ensures the service is acting on behalf of
    #   YOUR account, not an attacker's.
    #
    # CONFIGURATION PARAMETERS:
    #   - org_id: Your AWS Organization ID (used to validate source accounts)
    #   - enforced_service_actions: List of service actions that must include confused deputy protection
    #   - exclude_resource_arns: Resources exempt from this requirement (use sparingly)
    #
    # EXAMPLE COMPLIANT POLICY:
    #   {
    #     "Effect": "Allow",
    #     "Principal": {"Service": "cloudtrail.amazonaws.com"},
    #     "Action": "s3:PutObject",
    #     "Resource": "arn:aws:s3:::my-bucket/*",
    #     "Condition": {
    #       "StringEquals": {"aws:SourceAccount": "123456789012"}
    #     }
    #   }
    #
    # WARNING: Carefully test this policy as it may break existing service integrations that
    #          don't include proper source conditions. Update resource policies before deployment.
    #
    # DEPLOYMENT STRATEGY:
    #   1. Audit existing resource policies for compliance
    #   2. Update non-compliant policies to include source conditions
    #   3. Deploy to test environment first
    #   4. Monitor CloudTrail for denied requests
    #   5. Roll out to production after validation
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "rcp_enforce_confused_deputy_protection"
      policy_description = "Enforce confused deputy protection for s3, sqs, kms, secretsmanager and sts"
      target_ou_paths    = ["/root"]
      template_names     = ["enforce_confused_deputy_protection"]
      # Your AWS Organization ID - required for validating source account conditions
      # IMPORTANT: Use local variable or parameter store to avoid cyclic dependencies
      # DO NOT reference module.ntc_organizations.org_id directly
      org_id = local.organization_id
      # Services where confused deputy protection is enforced
      # CONFIGURATION: Add "*" wildcard to enforce for all actions in a service
      enforced_service_actions = [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        "sts:*",
      ]
      # Resource exceptions (resources exempt from confused deputy protection)
      # CONFIGURATION: Only add exceptions for resources with legitimate external service access
      # EXAMPLE: exclude_resource_arns = ["arn:aws:s3:::my-public-bucket/*"]
      exclude_resource_arns = [
        # NOTE: network firewall with kms cmk triggers confused deputy protection - exclude while investigating with aws support
        "arn:aws:kms:eu-central-1:944538260333:key/2bb3bfda-5446-4470-aa40-f74cea61ae85"
      ]
    },
    # -----------------------------------------------------------------------------------------------------------------
    # RCP 2: Organization Boundary Enforcement
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Prevent data exfiltration by ensuring resources can only be accessed by principals
    #          within your AWS Organization (implements organizational boundary)
    # 
    # TEMPLATE USED:
    #   - enforce_principal_access_from_organization: Requires aws:PrincipalOrgID condition
    #
    # SCOPE: Applied organization-wide (/root)
    #
    # DATA EXFILTRATION SCENARIO:
    #   Without this protection, a compromised IAM principal could create a resource policy
    #   granting access to an external AWS account, enabling data exfiltration.
    #
    # PROTECTION MECHANISM:
    #   Requires resource-based policies to include aws:PrincipalOrgID condition, ensuring
    #   only principals from your organization can access the resource.
    #
    # CONFIGURATION PARAMETERS:
    #   - org_id: Your AWS Organization ID
    #   - enforced_service_actions: Actions requiring organization principal validation
    #   - exclude_resource_arns: Resources needing external access (e.g., public S3 buckets)
    #   - exclude_principal_arns: External principals that legitimately need access
    #
    # EXAMPLE COMPLIANT POLICY:
    #   {
    #     "Effect": "Allow",
    #     "Principal": "*",
    #     "Action": "s3:GetObject",
    #     "Resource": "arn:aws:s3:::my-bucket/*",
    #     "Condition": {
    #       "StringEquals": {"aws:PrincipalOrgID": "o-xxxxxxxxxx"}
    #     }
    #   }
    #
    # EXCLUSION USE CASES:
    #   - Public websites hosted on S3
    #   - Resources shared with business partners
    #   - Integration with third-party SaaS providers
    #
    # WARNING: This creates a hard boundary preventing ALL external access unless explicitly excluded.
    #          Identify resources requiring external access BEFORE deployment.
    #
    # DEPLOYMENT STRATEGY:
    #   1. Identify resources with legitimate external access requirements
    #   2. Document business justification for each exclusion
    #   3. Update resource policies to include PrincipalOrgID conditions
    #   4. Add necessary exclusions to exclude_resource_arns or exclude_principal_arns
    #   5. Test in non-production environment
    #   6. Monitor CloudTrail for unexpected access denials
    #   7. Gradually roll out to production OUs
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "rcp_enforce_principal_access_from_organization"
      policy_description = "Enforce principal access from organization for s3, sqs, kms, secretsmanager and sts"
      target_ou_paths    = ["/root"]
      template_names     = ["enforce_principal_access_from_organization"]
      # Your AWS Organization ID - used for aws:PrincipalOrgID condition validation
      # IMPORTANT: Use local variable or parameter store to avoid cyclic dependencies
      org_id = local.organization_id
      # Services where organization boundary is enforced
      # CONFIGURATION: Add actions requiring organization principal validation
      enforced_service_actions = [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        # IMPORTANT: Limited STS actions to prevent conflicts with AWS IAM Identity Center (SSO)
        # Including all sts:* actions breaks Identity Center functionality
        "sts:AssumeRole",
        "sts:SetContext",
      ]
      # Resource exceptions (resources needing external access)
      # CONFIGURATION: Add resources that must be accessible outside your organization
      # EXAMPLES:
      #   - Public S3 buckets: ["arn:aws:s3:::my-public-website/*"]
      #   - Partner integrations: ["arn:aws:s3:::partner-data-exchange/*"]
      exclude_resource_arns = []
      # Principal exceptions (external principals requiring access)
      # CONFIGURATION: Add specific external principal ARNs when necessary
      # EXAMPLES:
      #   - Third-party vendor: ["arn:aws:iam::111122223333:role/VendorRole"]
      #   - Partner account: ["arn:aws:iam::444455556666:root"]
      exclude_principal_arns = []
    },
    # -----------------------------------------------------------------------------------------------------------------
    # RCP 3: Secure Transport (HTTPS/TLS) Enforcement
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Ensure all data in transit is encrypted by requiring HTTPS/TLS for all service requests
    # 
    # TEMPLATE USED:
    #   - enforce_secure_transport: Requires aws:SecureTransport condition
    #
    # SCOPE: Applied organization-wide (/root)
    #
    # SECURITY RISK:
    #   Without this protection, data could be transmitted over unencrypted HTTP connections,
    #   exposing sensitive information to network eavesdropping and man-in-the-middle attacks.
    #
    # PROTECTION MECHANISM:
    #   Requires resource-based policies to include aws:SecureTransport condition set to true,
    #   blocking all requests not made over HTTPS/TLS.
    #
    # CONFIGURATION PARAMETERS:
    #   - enforced_service_actions: Services requiring HTTPS/TLS
    #   - exclude_resource_arns: Resources exempt from secure transport requirement
    #
    # EXAMPLE COMPLIANT POLICY:
    #   {
    #     "Effect": "Allow",
    #     "Principal": "*",
    #     "Action": "s3:*",
    #     "Resource": "arn:aws:s3:::my-bucket/*",
    #     "Condition": {
    #       "Bool": {"aws:SecureTransport": "true"}
    #     }
    #   }
    #
    # ALTERNATIVELY (Deny approach):
    #   {
    #     "Effect": "Deny",
    #     "Principal": "*",
    #     "Action": "s3:*",
    #     "Resource": "arn:aws:s3:::my-bucket/*",
    #     "Condition": {
    #       "Bool": {"aws:SecureTransport": "false"}
    #     }
    #   }
    #
    # COMPLIANCE FRAMEWORKS:
    #   - PCI DSS: Requirement 4 (Encrypt transmission of cardholder data)
    #   - HIPAA: Transmission Security (164.312(e)(1))
    #   - GDPR: Article 32 (Security of processing)
    #
    # DEPLOYMENT NOTES:
    #   - Most AWS SDKs and tools use HTTPS by default
    #   - Legacy applications may need updates to support HTTPS
    #   - Test thoroughly before deployment to production
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "rcp_enforce_secure_transport"
      policy_description = "Enforce secure transport for s3, sqs, kms, secretsmanager and sts"
      target_ou_paths    = ["/root"]
      template_names     = ["enforce_secure_transport"]
      # Services where secure transport (HTTPS/TLS) is mandatory
      # CONFIGURATION: Add all services handling sensitive data
      enforced_service_actions = [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        "sts:*",
      ]
      # Resource exceptions (resources where HTTP may be acceptable)
      # CONFIGURATION: Use sparingly and only for non-sensitive public resources
      # WARNING: Excluding resources from secure transport reduces security posture
      exclude_resource_arns = []
    },
    # -----------------------------------------------------------------------------------------------------------------
    # RCP 4: S3 Encryption and TLS Version Enforcement
    # -----------------------------------------------------------------------------------------------------------------
    # PURPOSE: Enforce data-at-rest encryption using AWS KMS and require minimum TLS version for S3 access
    # 
    # TEMPLATES USED:
    #   1. enforce_s3_kms_encryption: Requires S3 objects to be encrypted with AWS KMS
    #   2. enforce_s3_tls_version: Enforces minimum TLS version for S3 requests
    #
    # SCOPE: Applied organization-wide (/root)
    #
    # SECURITY REQUIREMENTS:
    #   DATA AT REST:
    #     - All S3 objects must be encrypted using AWS KMS (SSE-KMS)
    #     - Blocks uploads of unencrypted objects
    #     - Blocks uploads using S3-managed encryption (SSE-S3) or customer-provided keys (SSE-C)
    #   
    #   DATA IN TRANSIT:
    #     - Enforces minimum TLS version to prevent use of outdated, vulnerable protocols
    #     - Protects against protocol downgrade attacks
    #
    # CONFIGURATION PARAMETERS:
    #   - s3_tls_minimum_version: Minimum TLS version required ("1.2" or "1.3")
    #   - exclude_resource_arns: S3 buckets exempt from these requirements
    #
    # WHY KMS OVER S3-MANAGED ENCRYPTION:
    #   ✓ Centralized key management and rotation
    #   ✓ Detailed access logging via CloudTrail
    #   ✓ Granular access controls via KMS key policies
    #   ✓ Ability to disable/delete keys for immediate data protection
    #   ✓ Cross-account encryption capabilities
    #   ✓ Integration with AWS CloudHSM for hardware-based key storage
    #
    # TLS VERSION CONSIDERATIONS:
    #   - TLS 1.2: Widely supported, meets most compliance requirements
    #   - TLS 1.3: Latest version with improved security and performance
    #   - TLS 1.0/1.1: Deprecated and vulnerable, should never be used
    #
    # COMPLIANCE FRAMEWORKS:
    #   - PCI DSS: Requirement 3 (Protect stored cardholder data)
    #   - PCI DSS: Requirement 4 (Use TLS 1.2 or higher)
    #   - HIPAA: Encryption at Rest (164.312(a)(2)(iv))
    #   - GDPR: Article 32 (Encryption of personal data)
    #   - BSI C5: Encryption requirements
    #
    # EXCLUSION USE CASES:
    #   - Public website assets (images, CSS, JS) that don't contain sensitive data
    #   - CloudFront distribution origin buckets (CloudFront handles encryption)
    #   - Temporary buckets for non-sensitive data processing
    #
    # DEPLOYMENT STRATEGY:
    #   1. Create KMS keys for S3 encryption if not already existing
    #   2. Update S3 bucket default encryption settings to use KMS
    #   3. Update application code to specify SSE-KMS for uploads
    #   4. Verify all S3 clients support TLS 1.2 or higher
    #   5. Test in non-production environment
    #   6. Monitor CloudTrail for encryption-related access denials
    #   7. Document any buckets added to exclusion list with justification
    # -----------------------------------------------------------------------------------------------------------------
    {
      policy_name        = "rcp_enforce_s3_encryption_and_tls_version"
      policy_description = "Enforce S3 encryption and TLS version"
      target_ou_paths    = ["/root"]
      template_names = [
        "enforce_s3_kms_encryption",
        "enforce_s3_tls_version",
      ]
      # Minimum TLS version for S3 access
      # CONFIGURATION OPTIONS:
      #   "1.2" - Recommended minimum, widely supported, meets PCI DSS requirements
      #   "1.3" - Latest version, best security, verify client compatibility first
      # SECURITY NOTE: TLS 1.0 and 1.1 are deprecated and must not be used
      s3_tls_minimum_version = "1.2"
      # S3 bucket exceptions (buckets exempt from encryption and TLS requirements)
      # CONFIGURATION: Only add buckets with documented business justification
      # EXAMPLES:
      #   - Public website: ["arn:aws:s3:::my-public-website"]
      #   - CloudFront origin: ["arn:aws:s3:::cdn-origin-bucket"]
      # IMPORTANT: Exclusions reduce security posture - use sparingly
      exclude_resource_arns = []
    },
  ]
}

# NOTE: you can import and manage an existing AWS Organization using the following import block:
# import {
#   to = module.ntc_organizations.aws_organizations_organization.ntc_org
#   id = "o-xxxxxxxx" # Replace with your existing organization ID
# }

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATIONS
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_organizations" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations?ref=2.0.1"

  region = "eu-central-1"
  # -------------------------------------------------------------------------------------------------------------------
  # AWS SERVICE INTEGRATIONS WITH ORGANIZATIONS
  # -------------------------------------------------------------------------------------------------------------------
  # Enable trusted access for AWS services to perform actions across your organization
  # 
  # WHAT THIS DOES:
  #   - Allows services to create service-linked roles in member accounts
  #   - Enables centralized management from the management account
  #   - Required for organization-wide features like GuardDuty, Security Hub, etc.
  # 
  # SECURITY NOTE: Only enable services you actually use to minimize attack surface
  # 
  # Reference: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html
  # -------------------------------------------------------------------------------------------------------------------
  service_access_principals = [
    "iam.amazonaws.com",                          # IAM - Identity and Access Management
    "account.amazonaws.com",                      # AWS Account Management
    "servicequotas.amazonaws.com",                # Service Quotas - Centralized quota management
    "cloudtrail.amazonaws.com",                   # CloudTrail - Organization-wide audit logging
    "securityhub.amazonaws.com",                  # Security Hub - Centralized security findings
    "config.amazonaws.com",                       # AWS Config - Compliance and configuration tracking
    "config-multiaccountsetup.amazonaws.com",     # AWS Config - Multi-account setup
    "guardduty.amazonaws.com",                    # GuardDuty - Threat detection
    "inspector2.amazonaws.com",                   # Inspector - Vulnerability management
    "macie.amazonaws.com",                        # Macie - Sensitive data discovery
    "malware-protection.guardduty.amazonaws.com", # GuardDuty Malware Protection
    "access-analyzer.amazonaws.com",              # IAM Access Analyzer - Identify unintended access
    "sso.amazonaws.com",                          # IAM Identity Center (SSO) - Centralized access
    "ipam.amazonaws.com",                         # IPAM - IP address management
    "backup.amazonaws.com",                       # AWS Backup - Centralized backup management
    "ram.amazonaws.com",                          # Resource Access Manager - Resource sharing
  ]

  # -----------------------------------------------------------------------------------------------------------------
  # ORGANIZATIONAL UNIT (OU) STRUCTURE
  # -----------------------------------------------------------------------------------------------------------------
  # Define the organizational hierarchy for account management and policy inheritance
  #
  # STRUCTURE:
  #   /root                    - Top-level organization (all policies here apply to entire org)
  #   ├── /root/core           - Core infrastructure accounts (network, security, log archive)
  #   ├── /root/sandbox        - Experimental/testing accounts with relaxed policies
  #   ├── /root/suspended      - Disabled accounts (all access blocked except org admin)
  #   ├── /root/transitional   - Accounts being migrated or decommissioned
  #   └── /root/workloads      - Production and non-production workload accounts
  #       ├── /root/workloads/prod - Production workloads (strictest policies)
  #       ├── /root/workloads/dev  - Development workloads
  #       └── /root/workloads/test - Testing workloads
  #
  # BEST PRACTICES:
  #   - Use nested OUs to inherit policies from parent OUs
  #   - Separate production from non-production for different security postures
  #   - Keep sandbox isolated for experimentation without affecting production
  #   - Use suspended/transitional OUs for security incidents or account lifecycle management
  # -----------------------------------------------------------------------------------------------------------------
  organizational_unit_paths = [
    "/root/core",
    "/root/sandbox",
    "/root/suspended",
    "/root/transitional",
    "/root/workloads",
    "/root/workloads/prod",
    "/root/workloads/dev",
    "/root/workloads/test"
  ]

  # -----------------------------------------------------------------------------------------------------------------
  # ORGANIZATION POLICIES - SECURITY GUARDRAILS
  # -----------------------------------------------------------------------------------------------------------------
  # This section applies Service Control Policies (SCPs), Resource Control Policies (RCPs), and other policies
  # to enforce security, compliance, and operational guardrails across your organization.
  #
  # POLICY TYPES:
  #   - SERVICE_CONTROL_POLICY: Define maximum permissions for IAM principals (never grants, only restricts)
  #   - RESOURCE_CONTROL_POLICY: Define maximum permissions for resources (what can be done TO a resource)
  #   - BACKUP_POLICY: Configure automated backup plans for AWS Backup
  #
  # POLICY APPLICATION:
  #   Policies are applied in order and inherited down the OU hierarchy. Multiple policies combine with
  #   logical AND - all applicable policies must allow an action for it to succeed.
  #
  # CONFIGURATION APPROACH:
  #   1. Start with baseline security (enabled below)
  #   2. Gradually add stricter controls as needed
  #   3. Test with dedicated accounts before applying to production
  #   4. Use commented alternatives for future hardening
  # -----------------------------------------------------------------------------------------------------------------
  organization_policies = [
    # EXAMPLE: Custom SCP (commented out - use for organization-specific policies)
    # You can define inline SCPs here if you have custom requirements not covered by guardrail templates
    # {
    #   policy_name        = "scp_deny_all_outside_eu_regions"
    #   policy_type        = "SERVICE_CONTROL_POLICY"
    #   target_ou_paths    = ["/root/workloads"]
    #   target_account_ids = []
    #   policy_json        = "INSERT_SCP_JSON"
    # }

    # ---------------------------------------------------------------------------------------------------------
    # BASELINE SERVICE CONTROL POLICIES (SCPs) - CURRENTLY ACTIVE
    # ---------------------------------------------------------------------------------------------------------
    # These policies are defined in 'ntc_organizations_guardrails.tf' and provide foundational security controls
    # See that file for detailed documentation on each policy's purpose and configuration
    # ---------------------------------------------------------------------------------------------------------

    # SCP 1: Organization-wide Security Baseline
    # Prevents accounts from leaving org, blocks root user actions, denies IAM user creation
    # Applied to: /root (entire organization)
    module.ntc_guardrail_templates.service_control_policies["scp_root_ou"],

    # SCP 2: Suspended/Transitional Account Lockdown
    # Blocks all AWS service access for suspended or transitional accounts
    # Applied to: /root/suspended, /root/transitional
    module.ntc_guardrail_templates.service_control_policies["scp_suspended_ou"],

    # SCP 3: Regional Restriction for Workloads
    # Enforces data residency by restricting actions to allowed regions (currently: eu-central-1, eu-central-2)
    # Applied to: /root/workloads (including prod, dev, test)
    module.ntc_guardrail_templates.service_control_policies["scp_workloads_ou"],

    # ---------------------------------------------------------------------------------------------------------
    # ALTERNATIVE SCPs - STRICTER SECURITY POSTURES (COMMENTED OUT)
    # ---------------------------------------------------------------------------------------------------------
    # Use these instead of 'scp_workloads_ou' for enhanced security. Test thoroughly before enabling in production!
    #
    # OPTION A: BSI C5 Compliance Mode
    #   - Restricts to BSI C5-certified AWS services only
    #   - Enforces EU data residency
    #   - Required for German Federal Office compliance
    #   - Use case: Government, highly regulated industries in Germany
    #   - ⚠️ WARNING: Significantly limits available AWS services
    # ---------------------------------------------------------------------------------------------------------
    # module.ntc_guardrail_templates.service_control_policies["scp_c5_compliance"],

    # ---------------------------------------------------------------------------------------------------------
    # OPTION B: Service Whitelisting (Defense-in-Depth)
    #   - Combines regional restrictions with explicit service approval
    #   - Only explicitly whitelisted services can be used
    #   - Use case: High-security environments requiring explicit service approval
    #   - ⚠️ WARNING: Creates deny-by-default posture. Coordinate with teams before enabling.
    # ---------------------------------------------------------------------------------------------------------
    # module.ntc_guardrail_templates.service_control_policies["scp_workloads_ou_whitelisting"],

    # ---------------------------------------------------------------------------------------------------------
    # RESOURCE CONTROL POLICIES (RCPs) - CURRENTLY ACTIVE
    # ---------------------------------------------------------------------------------------------------------
    # RCPs control what can be done TO resources (complementary to SCPs which control what principals CAN DO)
    # These policies prevent data exfiltration and enforce security best practices at the resource level
    # ---------------------------------------------------------------------------------------------------------

    # RCP 1: Confused Deputy Protection
    # Prevents AWS services from being tricked into accessing your resources on behalf of attackers
    # Requires aws:SourceAccount or aws:SourceArn conditions in resource policies
    # Applied to: /root (entire organization)
    # Enforced for: S3, SQS, KMS, Secrets Manager, STS
    module.ntc_guardrail_templates.resource_control_policies["rcp_enforce_confused_deputy_protection"],

    # RCP 2: Organization Boundary Enforcement
    # Prevents data exfiltration by ensuring resources only accessible by org principals
    # Requires aws:PrincipalOrgID condition in resource policies
    # Applied to: /root (entire organization)
    # Enforced for: S3, SQS, KMS, Secrets Manager, STS
    module.ntc_guardrail_templates.resource_control_policies["rcp_enforce_principal_access_from_organization"],

    # RCP 3: Secure Transport (HTTPS/TLS) Enforcement
    # Ensures all data in transit is encrypted by requiring HTTPS/TLS
    # Blocks all HTTP requests to supported services
    # Applied to: /root (entire organization)
    # Enforced for: S3, SQS, KMS, Secrets Manager, STS
    module.ntc_guardrail_templates.resource_control_policies["rcp_enforce_secure_transport"],

    # RCP 4: S3 Encryption and TLS Version Requirements
    # Enforces AWS KMS encryption for S3 objects and minimum TLS version (1.2)
    # Blocks uploads without SSE-KMS encryption
    # Applied to: /root (entire organization)
    # Enforced for: S3 only
    module.ntc_guardrail_templates.resource_control_policies["rcp_enforce_s3_encryption_and_tls_version"],
  ]

  # -------------------------------------------------------------------------------------------------------------------
  # CLOUDTRAIL ORGANIZATION TRAIL - CENTRALIZED AUDIT LOGGING
  # -------------------------------------------------------------------------------------------------------------------
  # Create an organization-wide CloudTrail that logs API activity across ALL accounts
  # 
  # PREREQUISITES:
  #   ⚠️  S3 log archive bucket MUST be provisioned BEFORE creating the organization trail
  #   ⚠️  KMS key for CloudTrail encryption must exist and have proper key policy
  #   
  # WHAT THIS LOGS:
  #   - All AWS API calls across all accounts in the organization
  #   - Management events (control plane operations like creating EC2 instances)
  #   - Optional: Data events (data plane operations like S3 object access)
  # 
  # SECURITY & COMPLIANCE:
  #   ✓ Required for SOC 2, ISO 27001, PCI DSS compliance
  #   ✓ Critical for incident response and forensics
  #   ✓ Enables detective controls for security threats
  #   ✓ Immutable audit trail (when S3 bucket has proper policies)
  # 
  # CLOUDWATCH INTEGRATION:
  #   - Enables real-time monitoring and alerting
  #   - Allows metric filters for specific API calls
  #   - Powers CloudWatch Alarms for security events
  #   - Small additional cost but provides immediate visibility
  # -------------------------------------------------------------------------------------------------------------------
  organization_trail = {
    kms_key_arn    = local.ntc_parameters["log-archive"]["log_bucket_kms_key_arns"]["org_cloudtrail"]
    s3_bucket_name = local.ntc_parameters["log-archive"]["log_bucket_ids"]["org_cloudtrail"]

    # Enable real-time CloudWatch Logs for immediate visibility and alerting
    cloud_watch_logs_enable            = false
    cloud_watch_logs_retention_in_days = 30
    # cloud_watch_logs_existing   = false                    # Set to true if log group already exists
    # cloud_watch_logs_group_name = "organization-trail-logs" # Customize log group name
    # cloud_watch_logs_role_name  = "organization-trail-logs" # Customize IAM role name
  }

  # -------------------------------------------------------------------------------------------------------------------
  # CENTRALIZED ROOT ACCESS MANAGEMENT
  # -------------------------------------------------------------------------------------------------------------------
  # NEW FEATURE: Manage root user credentials from the management account (available late 2024)
  # 
  # SECURITY BENEFITS:
  #   ✓ Eliminates risk of forgotten root credentials in member accounts
  #   ✓ Prevents unauthorized root access in individual accounts
  #   ✓ Enables centralized audit of all root user activities
  #   ✓ Simplifies root credential management across hundreds of accounts
  #   ✓ New accounts created have NO root credentials by default
  # 
  # FEATURES:
  #   1. RootCredentialsManagement:
  #      - Delete root user passwords from member accounts
  #      - Audit root credential usage across organization
  #      - Enable password recovery for specific accounts when needed (break-glass)
  #      - Root credentials managed only from management account
  # 
  #   2. RootSessions:
  #      - Perform privileged root actions from management account
  #      - Break-glass access for emergency situations:
  #        * Delete misconfigured resource policies (S3, SQS, KMS)
  #        * Fix broken IAM policies blocking all access
  #        * Recover from lockout situations
  #      - All actions logged in CloudTrail for audit
  # 
  # Reference: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-enable-root-access.html
  # -------------------------------------------------------------------------------------------------------------------
  centralize_root_access = {
    enabled = true
    features = [
      "RootCredentialsManagement", # Centrally manage root credentials (delete, audit, recovery)
      "RootSessions",              # Perform emergency root actions from management account
    ]
  }

  # -------------------------------------------------------------------------------------------------------------------
  # ORGANIZATION READER ROLE - CROSS-ACCOUNT READ ACCESS
  #-------------------------------------------------------------------------------------------------------------------
  # Create a read-only IAM role for viewing organization structure and account information
  # 
  # PURPOSE:
  #   Enable security/audit accounts to query organization metadata without write permissions
  # 
  # PERMISSIONS GRANTED:
  #   - organizations:Describe* (view org structure, OUs, accounts)
  #   - organizations:List* (list accounts, policies, OUs)
  #   - Read-only access to organization metadata
  #   - NO write permissions (cannot modify organization)
  # 
  # USE CASES:
  #   - Security tooling: Discover accounts for security scanning
  #   - Compliance automation: Audit account structure and policies
  #   - Cost management: Identify accounts for billing analysis
  #   - Asset inventory: Map accounts to business units
  #   - CMDB integration: Sync organization data to configuration management
  # 
  # SECURITY CONSIDERATIONS:
  #   ✓ Read-only access reduces blast radius
  #   ✓ Use specific account IDs (not wildcards) in allowed_principals
  #   ✓ Monitor role assumption in CloudTrail
  #   ✓ Consider using external ID for third-party integrations
  # 
  # CONFIGURATION:
  #   - allowed_principals: List of account IDs or IAM principals that can assume this role
  #   - Typically granted to: Security account, audit account, automation accounts
  # -------------------------------------------------------------------------------------------------------------------
  organization_reader = {
    enabled = true
    # IAM principals allowed to assume this role (recommended: specific account IDs)
    allowed_principals = [
      local.security_account_id
    ]
    iam_role_name   = "ntc-org-account-reader"
    iam_role_path   = "/"
    iam_policy_name = "ntc-org-account-reader-policy"
  }

  # -------------------------------------------------------------------------------------------------------------------
  # SERVICE QUOTA TEMPLATES - AUTOMATIC QUOTA INCREASES FOR NEW ACCOUNTS
  # -------------------------------------------------------------------------------------------------------------------
  # Automatically apply service quota increases to ALL new accounts created in the organization
  # 
  # HOW IT WORKS:
  #   - Templates are applied when new accounts are created
  #   - Eliminates manual quota increase requests for each new account
  #   - Ensures consistent quotas across all accounts
  # 
  # IMPORTANT LIMITATIONS:
  #   ⚠️  Only applies to NEW accounts (not existing accounts)
  #   ⚠️  Not supported in opt-in regions (e.g., Zurich, Middle East, Africa regions)
  #   ⚠️  Global quotas must be applied in us-east-1 region (aws commercial partition)
  #   ⚠️  Some quotas require AWS support approval (not all can be auto-increased)
  # 
  # WHEN TO USE:
  #   - Your organization frequently hits default quotas
  #   - You create many accounts and need consistent quotas
  #   - You want to prevent quota-related failures in new accounts
  # 
  # QUOTA TYPES:
  #   - Regional quotas: Apply to specific regions (e.g., EC2 instances in eu-central-1)
  #   - Global quotas: Apply account-wide (e.g., IAM policies per role)
  # 
  # FINDING QUOTA CODES:
  #   1. AWS Console → Service Quotas → AWS services → Select service
  #   2. AWS CLI: aws service-quotas list-service-quotas --service-code <code>
  #   3. Common service codes: ec2, vpc, elasticloadbalancing, iam, lambda, s3, rds
  # -------------------------------------------------------------------------------------------------------------------
  service_quota_templates = [
    {
      # Regional quota: Increase SSL/TLS certificates per ALB in multiple regions
      regions      = ["eu-central-1", "us-east-1"]
      quota_name   = "Certificates per Application Load Balancer"
      service_code = "elasticloadbalancing"
      new_value    = 30 # Default: 25, Increased for multi-domain ALBs
    },
    {
      # Increase managed IAM policies per role (useful for modular IAM design)
      regions      = ["us-east-1"] # REQUIRED: Global IAM quotas use us-east-1
      quota_name   = "Managed policies per role"
      service_code = "iam"
      new_value    = 20 # Default: 10, Increased for complex permission models
    }
  ]

  # -------------------------------------------------------------------------------------------------------------------
  # DELEGATED ADMINISTRATORS - SERVICE DELEGATION
  # -------------------------------------------------------------------------------------------------------------------
  # Delegate administration of specific AWS services to designated accounts (typically Security, Backup, or Network)
  # 
  # PREREQUISITES:
  #   ⚠️  Service must be enabled in 'service_access_principals' above (enables trusted access with Organizations)
  #   ⚠️  Delegated administrator account must already exist in the organization
  #   ⚠️  Delegated admin must be a MEMBER account (cannot use management account)
  # 
  # WHY DELEGATE:
  #   ✓ Centralized management from specialized accounts (security, backup, networking)
  #   ✓ Separation of duties: Management account for org structure, specialized accounts for their domains
  #   ✓ Reduced risk: Limits blast radius if management account is compromised
  #   ✓ Best practice: AWS recommends minimal usage of management account
  # 
  # DELEGATION TYPES:
  # 
  #   GLOBAL DELEGATION (once per organization):
  #     Services delegated organization-wide, not per region:
  #     - AWS Config: Centrally manage compliance rules across organization
  #     - IAM Access Analyzer: Analyze resource policies organization-wide
  #     - AWS Backup: Centralized backup management and policies
  #     - CloudFormation StackSets: Cross-account deployments
  #     - Organizations, SSO/Identity Center, etc.
  # 
  #   REGIONAL DELEGATION (per region):
  #     Services requiring delegation in EACH region you operate:
  #     - Security Hub: Aggregate security findings per region
  #     - GuardDuty: Threat detection per region
  #     - Inspector: Vulnerability scanning per region
  #     - Macie: Sensitive data discovery per region
  #     - Audit Manager: Compliance auditing per region
  #     - IPAM: IP address management per region (optional - can also run centralized without delegation)
  # 
  # DELEGATION PROCESS:
  #   1. Service must be enabled in Organizations (via service_access_principals)
  #   2. Delegated admin account receives permissions to manage service org-wide/regionally
  #   3. Member accounts are automatically enrolled/managed by delegated admin
  # 
  # COMMON PATTERNS:
  #   - Security services → Security account (creates centralized SOC)
  #   - Backup → Backup/Log Archive account (centralized backup management)
  #   - IPAM → Network account (centralized IP address management)
  # -------------------------------------------------------------------------------------------------------------------
  delegated_administrators = [
    {
      service_principal = "securityhub.amazonaws.com"
      admin_account_id  = local.security_account_id
      regions = [
        "eu-central-1",
        "eu-central-2",
        "us-east-1",
      ]
    },
    {
      service_principal = "guardduty.amazonaws.com"
      admin_account_id  = local.security_account_id
      regions = [
        "eu-central-1",
        "eu-central-2",
        "us-east-1",
      ]
    },
    {
      service_principal = "inspector2.amazonaws.com"
      admin_account_id  = local.security_account_id
      regions = [
        "eu-central-1",
        "eu-central-2",
        "us-east-1",
      ]
    },
    {
      service_principal = "config.amazonaws.com"
      admin_account_id  = local.security_account_id
      regions = [
        "eu-central-1",
        "eu-central-2",
        "us-east-1",
      ]
    },
    {
      service_principal = "access-analyzer.amazonaws.com"
      admin_account_id  = local.security_account_id
      regions = [
        "eu-central-1",
      ]
    },
    {
      service_principal = "backup.amazonaws.com"
      admin_account_id  = local.backup_account_id
      regions = [
        "eu-central-1",
      ]
    },
  ]

  # NOTE: 'aws.global_service_region' configuration_alias is only required for 'var.service_quota_templates'
  # in aws commercial partition, service quota templates must be applied from the 'us-east-1' region
  providers = {
    aws.global_service_region = aws.use1
  }
}

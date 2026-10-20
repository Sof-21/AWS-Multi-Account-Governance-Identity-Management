
# Troubleshooting

## Organization root issue
### Error

During terraform apply, AWS returned an invalid value for parent_id error when Terraform attempted to create the Development and Production organizational units.

```
╷
│ Error: invalid value for parent_id (see https://docs.aws.amazon.com/organizations/latest/APIReference/API_CreateOrganizationalUnit.html#organizations-CreateOrganizationalUnit-request-ParentId)
│ 
│   with aws_organizations_organizational_unit.nimbus-dev-ou,
│   on aws_org_units.tf line 6, in resource "aws_organizations_organizational_unit" "nimbus-dev-ou":
│    6:   parent_id = aws_organizations_organization.nimbus-cloud.id
│ 
╵
╷
│ Error: invalid value for parent_id (see https://docs.aws.amazon.com/organizations/latest/APIReference/API_CreateOrganizationalUnit.html#organizations-CreateOrganizationalUnit-request-ParentId)
│ 
│   with aws_organizations_organizational_unit.nimbus-prod-ou,
│   on aws_org_units.tf line 12, in resource "aws_organizations_organizational_unit" "nimbus-prod-ou":
│   12:   parent_id = aws_organizations_organization.nimbus-cloud.id

```
### Cause
I was passing the organization ID instead of the ID of the parent container where the organizational unit should be created.

In AWS Organizations, top-level organizational units must be created under the organization's root

```
resource "aws_organizations_organizational_unit" "nimbus-dev-ou" {
  name      = "Nimbus Development"
  parent_id = aws_organizations_organization.nimbus-cloud.id
}

resource "aws_organizations_organizational_unit" "nimbus-prod-ou" {
  name      = "Nimbus Production"
  parent_id = aws_organizations_organization.nimbus-cloud.id
}
```
### Resolution

I updated the parent_id references to use the organization's root ID:



```
resource "aws_organizations_organizational_unit" "nimbus-dev-ou" {
  name      = "Nimbus Development"
  parent_id = aws_organizations_organization.nimbus-cloud.roots[0].id
}

resource "aws_organizations_organizational_unit" "nimbus-prod-ou" {
  name      = "Nimbus Production"
  parent_id = aws_organizations_organization.nimbus-cloud.roots[0].id
}
```
For a standard AWS Organization, roots[0].id references the organization's root, which is the top-level container in the hierarchy.

### Lesson learned: 
When creating an organizational unit, use the ID of its parent root or parent OU, rather than the organization ID.

## Issue with SCP creation

### Error

When Terraform attempted to create the Service Control Policy (SCP), AWS returned the following error:

```
│ Error: creating Organizations Policy (Nimbus Organization SCP): operation error Organizations: CreatePolicy, https response error StatusCode: 400, RequestID: 4af2e3b6-5a77-413d-bc02-adf8d219425a, AWSOrganizationsNotInUseException: Your account is not a member of an organization.
│ 
│   with aws_organizations_policy.NimbusOrgScp,
│   on service_control_policy.tf line 46, in resource "aws_organizations_policy" "NimbusOrgScp":
│   46: resource "aws_organizations_policy" "NimbusOrgScp" {
│

```
Tf code snippet to create SCP

```
resource "aws_organizations_policy" "NimbusOrgScp" {
  name        = "Nimbus Organization SCP"
  description = "Service Control Policy for Nimbus cloud Organization"
  content     = data.aws_iam_policy_document.NimbusOrgIamPolicy.json
  type        = "SERVICE_CONTROL_POLICY"
}

# Policy attachment
resource "aws_organizations_policy_attachment" "NimbusDevScpAttch" {
  policy_id = aws_organizations_policy.NimbusOrgScp.id
  target_id = aws_organizations_organizational_unit.nimbus-dev-ou.id
}

resource "aws_organizations_policy_attachment" "NimbusProdScpAttch" {
  policy_id = aws_organizations_policy.NimbusOrgScp.id
  target_id = aws_organizations_organizational_unit.nimbus-prod-ou.id
}
```
### Cause

Since i did not specify which resource needs to be created first, tf looks to be trying to create the policy first, prior to creating the organization and in doing so, it could not find the associated organaization and threw an error. 

### Resolution
Issue was fixed, by applying the `depends-on` argument, for tf to wait for org creation before creating scp. 

```
resource "aws_organizations_policy" "NimbusOrgScp" {
  name        = "Nimbus Organization SCP"
  description = "Service Control Policy for Nimbus cloud Organization"
  content     = data.aws_iam_policy_document.NimbusOrgIamPolicy.json
  type        = "SERVICE_CONTROL_POLICY"

  # the below tells tf to wait for the organization to be created before applying the policy

  depends_on = [aws_organizations_organization.nimbus-cloud]
}
```
This tells Terraform to create the organization before creating the SCP. The policy attachments also reference the SCP and organizational units, allowing Terraform to infer those dependencies.

### Lesson learned:
 Terraform automatically determines resource creation order when dependencies are expressed through references. Use depends_on when Terraform cannot infer a required dependency.

**Note:** terraform validate checks Terraform configuration syntax and consistency; it does not make AWS API calls. The AWS Organizations error occurred during an operation such as terraform apply.

## SCP policy fails creation due to missing setting
After resolving the organization dependency, Terraform failed to attach the SCP to the Development and Production organizational units.

AWS returned the following error:
```
│ Error: creating Organizations Policy Attachment (ou-v3x9-c9057qdg:p-3tes25yl): operation error Organizations: AttachPolicy, https response error StatusCode: 400, RequestID: 2b993afb-6c2f-43f5-9d2b-b7b454731313, PolicyTypeNotEnabledException: This operation can be performed only for enabled policy types.
│ 
│   with aws_organizations_policy_attachment.NimbusDevScpAttch,
│   on service_control_policy.tf line 59, in resource "aws_organizations_policy_attachment" "NimbusDevScpAttch":
│   59: resource "aws_organizations_policy_attachment" "NimbusDevScpAttch" {
│ 
╵
╷
│ Error: creating Organizations Policy Attachment (ou-v3x9-jflkd6vy:p-3tes25yl): operation error Organizations: AttachPolicy, https response error StatusCode: 400, RequestID: 538c0255-085a-4202-bb67-ee46d5c91011, PolicyTypeNotEnabledException: This operation can be performed only for enabled policy types.
│ 
│   with aws_organizations_policy_attachment.NimbusProdScpAttch,
│   on service_control_policy.tf line 64, in resource "aws_organizations_policy_attachment" "NimbusProdScpAttch":
│   64: resource "aws_organizations_policy_attachment" "NimbusProdScpAttch" 

```


### Cause

The organization existed, but the Service Control Policy policy type had not been enabled. AWS Organizations requires SCPs to be enabled at the organization level before they can be attached to organizational units.

### Resolution
I applied the `enabled_policy_types` to the `aws_organizations_organization` resource. 




```
resource "aws_organizations_organization" "nimbus-cloud" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com", # allow organization wide cloud trail
    "config.amazonaws.com",     # allow organization wide configuration for future use.
    "sso.amazonaws.com"         # allow iam identity center for centralized identity management
  ]

  feature_set = "ALL"

  # protection against accidental tf destroy
  lifecycle {
    prevent_destroy = true
  }

  # Add this line to enable Service Control Policies
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}

```
After enabling the policy type, Terraform could attach the SCP to the Development and Production OUs.

### Lesson learned:
Enabling all features with feature_set = "ALL" does not remove the need to configure the policy types required by the organization. SCPs must be enabled before they can be attached.

## Terraform State Lock: DNS and Connectivity Failure
### Errors

During a Terraform operation, AWS provider credential validation failed when Terraform attempted to retrieve the caller identity from AWS STS:
```
│ Error: Retrieving AWS account details: validating provider credentials: retrieving caller identity from STS: operation error STS: GetCallerIdentity, https response error StatusCode: 0, RequestID: , request send failed, Post "https://sts.us-east-1.amazonaws.com/": dial tcp: lookup sts.us-east-1.amazonaws.com: no such host
│ 
│   with provider["registry.terraform.io/hashicorp/aws"],
│   on providers.tf line 11, in provider "aws":
│   11: provider "aws" {

```

A subsequent Terraform operation failed to acquire the S3 backend state lock: 

```
Error: Error acquiring the state lock
│ 
│ Error message: operation error S3: PutObject, https response error StatusCode: 412, RequestID: SP72NGT2SSJABAVV, HostID:
│ uq27bE+Ue3XlPw5WV4djh9rC0HawSS58SwNEe23v9bSCNn94i7qt5GdlgVMYlIVlGVnTtSfcl4r3qH8kjxhAl8jucvDfVDVu, api error PreconditionFailed: At least one of the pre-conditions you specified did not hold
│ Lock Info:
│   ID:        f04bd706-1e54-aabd-9361-5cbe8f95b38f
│   Path:      sof-terraform-projects-states/aws-multi-account-governance-identity-management/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       saberra@Sofis-MacBook-Air.local
│   Version:   1.16.2
│   Created:   2026-10-13 15:34:47.943415 +0000 UTC
│   Info:      
│ 
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
```
### Cause

The STS error indicated a DNS resolution or network connectivity problem. It did not necessarily mean that the AWS session had expired.

The subsequent error indicated that Terraform could not acquire the state lock. The previous operation may have terminated unexpectedly without releasing the lock, but a lock error alone does not confirm that the lock is stale.

### Resolution

The safe recovery process i used was:
- Verify if connectivity is restored
- Confirm that no terraform process is still running
- Retried once more the failed terraform command
- Finally after confirming the lock remained stale, i run:


```
terraform force-unlock f04bd706-1e54-aabd-9361-5cbe8f95b38f
```
### Lesson learned:
Terraform state locking protects shared state from concurrent modifications. Always investigate the original failure and confirm that the lock is stale before removing it.

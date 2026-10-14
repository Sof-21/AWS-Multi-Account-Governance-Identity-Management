
# Troubleshooting

## Organization root issue
When applying tf apply, the first error i got was the below. 

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
my organizational unit tf file was the below. 
i was passing the id of the organization, aws expects the id of the organization's root. 

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

I corrected the tf code by using the root[0].id reference, which obtains the highest hierarchy account or in this case the Org root. 

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


## Issue with SCP creation
once fixed the above issue, i run tf validate and got another error as below. 

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

Since i did not specify which resource needs to be created first, tf looks to be trying to create the policy first, prior to creating the organization and in doing so, it could not find the associated organaization and throw an error. 

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

## SCP policy fails creation due to missing setting
Even after fixing the dependency above, SCP creation was failing with the below error messaage from terraform. 

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

After further checking looks like we need to enable the policy type at organization level, and i missed this on my initial bootstrap, after checking the needed doc, i applied the `enabled_policy_types` to the `aws_organizations_organization` resource. 

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

## Error acquiring the state lock
During tf planning and applying my aws session timed out or faceed some connectivity issue and got the below error.
```
│ Error: Retrieving AWS account details: validating provider credentials: retrieving caller identity from STS: operation error STS: GetCallerIdentity, https response error StatusCode: 0, RequestID: , request send failed, Post "https://sts.us-east-1.amazonaws.com/": dial tcp: lookup sts.us-east-1.amazonaws.com: no such host
│ 
│   with provider["registry.terraform.io/hashicorp/aws"],
│   on providers.tf line 11, in provider "aws":
│   11: provider "aws" {

```
Terraform was in the middle of planning and applying which means it had a state lock on my s3 back end ts state file. hence it also threw the below error, for any subsequent tf apply or plan commands. 

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

To fix thee above, i run the below command to force unlock the state file. 

```
terraform force-unlock f04bd706-1e54-aabd-9361-5cbe8f95b38f
```

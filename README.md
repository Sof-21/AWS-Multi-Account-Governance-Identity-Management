# Nimbus Cloud: AWS Multi-Account Governance & Identity Management

## Project Summary

This project demonstrates the design and implementation of a governed, multi-account AWS environment using AWS Organizations, AWS IAM Identity Center, and Terraform. The scenario is based on a fictional company, Nimbus Cloud, that requires centralized workforce access, separation between development and production environments, and organization-level security guardrails.

### Problems Solved
- **Account governance:** Organized separate development and production AWS accounts under AWS Organizations.
- **Security guardrails:** Applied Service Control Policies (SCPs) to restrict selected high-risk actions, including leaving the organization and deleting selected security and infrastructure resources.
- **Centralized identity management:** Configured IAM Identity Center to manage users, groups, permission sets, and account assignments.
- **Role-based access:** Assigned permissions according to the responsibilities of DevOps, Developers, Support, and Human Resources.
- **Sensitive data protection:** Restricted HR access to designated reports stored in an S3 bucket in the production account.
- **Consolidated billing:** Centralized billing across all AWS accounts under AWS Organizations, enabling all usage, costs, and payment management to be observed and accessed in one place.
- **Infrastructure as code:** Used Terraform to manage the organization foundation and Identity Center configuration through separate root configurations.


### Technology Stack
- **AWS:** Organizations, IAM Identity Center, IAM, SCPs.
- **Terraform:** Infrastructure provisioning and configuration management.
- **Amazon S3:** Remote Terraform state storage.
- **Git:** Version control and change tracking.

<p align="left">
  <img src="https://skillicons.dev/icons?i=terraform,aws,git" />
</p>

### Architecture
The architecture illustrates the separation of management, development, and production responsibilities, with centralized identity management and organization-level guardrails.

!["Nimbus Cloud Architecture"](/Docs/Screenshots/repoImages/Nimbus%20Cloud%20AWS%20Governance.png)

> **Project scope:** Nimbus Cloud is a fictional company used to frame a portfolio implementation. This project demonstrates selected AWS governance and identity-management patterns; it is not a complete production landing zone.

---
<br>
<br>

## Chapter One: Design and Architecture

### 1.1 Business Scenario
Nimbus Cloud is expanding its use of AWS and needs a consistent approach to managing accounts, workforce identities, and access to cloud resources. 

The company has established separate development and production environments. Its engineering and business teams require different levels of access, while selected security and infrastructure operations must remain restricted.

The project addresses these requirements by implementing AWS Organizations, SCPs, and IAM Identity Center, with Terraform used to manage the majority of the configuration.

### 1.2 Project Objectives
1. Establish AWS Organizations and create separate development and production member accounts.
2. Organize member accounts into dedicated DEV and PROD organizational units (OUs).
3. Apply SCPs to restrict selected high-risk operations within the member accounts.
4. Configure IAM Identity Center for centralized workforce access.
5. Create four teams: DevOps, Developers, Support, and Human Resources.
6. Assign permission sets according to each team's responsibilities.
7. Restrict HR access to approved reports in the production S3 bucket.
8. Validate both permitted and denied actions.
9. Document implementation decisions, deployment procedures, limitations, and cleanup considerations.

### 1.3 Account and Organizational Structure
The organization uses a management account and two member accounts:

| Account / Component | Purpose |
| :--- | :--- |
| **Management account** | Manages AWS Organizations and organization-level governance |
| **Nimbus Development account** | Hosts development resources and ECR testing |
| **Nimbus Production account** | Represents the production environment and hosts the HR reports bucket |
| **Nimbus Dev OU** | Contains the development member account |
| **Nimbus Prod OU** | Contains the production member account |

The SCP is attached to both the development and production OUs. The management account is intentionally excluded from these OU-level SCP attachments during this initial implementation. 

This allows the guardrails to be validated against the member accounts before considering whether equivalent or less restrictive controls should be applied to the management account.

### 1.4 Team Access Model
The following table represents the implemented access model.

| Team | DEV Account | PROD Account | Access Rationale |
| :--- | :--- | :--- | :--- |
| **DevOps** | `DevOps_Permission` — Administrator Access | `DevOps_Permission` — Administrator Access | Manage and maintain cloud infrastructure |
| **Developers** | `Developer_Crucial_Permission` — ECR-focused access | `Support_ReadOnly_Permission` — read-only access | Create and manage ECR repositories in DEV while restricting production changes |
| **Support** | `Support_ReadOnly_Permission` — read-only access | `Support_ReadOnly_Permission` — read-only access | Inspect infrastructure and investigate operational issues |
| **Human Resources** | No access assignment | `HumanResources_Permission` — restricted S3 report access | Retrieve designated HR reports without broad AWS access |

The Developers and Support teams share the same read-only permission set in production because their required access is equivalent for this implementation. A separate developer-specific read-only permission set is not required for the current design.

DevOps receives administrative access to both member accounts because the team is responsible for infrastructure operations. SCPs provide additional guardrails by denying selected actions even when an assigned permission set would otherwise permit them.

### User Accounts
The following user account will need to be created and enrolled into respective teams.

| Team | Demonstration user | Username |
|---|---|---|
| Human Resources | Rachel Marcus | `rmarcus` |
| Support | Zack Parker | `zparker` |
| Developer | Leo Vance | `lvance` |
| DevOps | Jack Mayer | `jmayer` |


> *Disclaimer: These demonstration users are fictional and created solely for this project. Any resemblance to actual persons, living or deceased, is purely coincidental.*

### 1.5 Security Design

#### Service Control Policies
SCPs define the maximum permissions available to principals in affected member accounts. They do not grant permissions; IAM policies and other applicable authorization mechanisms must still allow an operation.

The `NimbusOrgIamPolicy` service control policy is attached to both the DEV and PROD OUs. 

Its deny statements cover two broad categories:
- **Organization and account governance:** Deny `organizations:DeleteOrganization`, `organizations:LeaveOrganization`, and `organizations:MoveAccount`.
- **Protection of selected resources:** Deny specified CloudTrail deletion and logging-control actions, S3 bucket and object deletion actions, ECR repository and lifecycle-policy deletion, and EKS cluster and associated resource deletion.

The intent is to prevent selected high-risk operations from being performed by principals in the affected member accounts, including principals with broad administrative IAM permissions.

The management account is not covered by these OU-level SCP attachments. This is an intentional initial design decision so that the controls can be tested and monitored in DEV and PROD before considering further restrictions.

#### Human Resources S3 Access
HR access is limited to the production account and the designated `hr-yearly-report` S3 bucket.

The custom permission set allows:
- `s3:ListAllMyBuckets` - list buckets visible through the S3 console.
- `s3:ListBucket` -  list objects in the designated bucket.
- `s3:GetObject` - download objects from the designated bucket.

The policy does not grant upload or delete permissions. The validation section documents the observed results of these restrictions.

#### Terraform State Management
The `orgbootstrap/` and `identity-center/` directories are separate Terraform root configurations with separate backend configuration.

The remote state is stored in Amazon S3, with state locking configured using `use_lockfile = true`. The state bucket is located in `eu-north-1`, separate from the Identity Center Region.

Access to the bucket is restricted via Bucket/trust policies because Terraform state can contain sensitive configuration details.

---
<br>
<br>

## Chapter Two: Implementation

### 2.1 Implementation Overview
The project is divided into two Terraform root configurations to separate organization governance from workforce identity management.

```text
.
├── orgbootstrap/
│   ├── providers.tf
│   ├── organizations.tf
│   ├── accounts.tf
│   ├── organizational_units.tf
│   ├── scp.tf
│   ├── backend.tf
│   ├── outputs.tf
│   └── variables.tf
│
├── identity-center/
│   ├── providers.tf
│   ├── backend.tf
│   ├── groups.tf
│   ├── users.tf
│   ├── permission_sets.tf
│   ├── identity-store.tf
│   ├── outputs.tf
│   └── variables.tf
│
└── README.md
```

The file names above describe the intended project structure. Resource declarations should be consulted for the exact implemented configuration.

####  `orgbootstrap/`
Responsible for:
- AWS Organizations configuration.
- Development and production member accounts.
- DEV and PROD organizational units.
- SCP definitions and OU attachments.
- Outputs for values needed by the Identity Center configuration, including member account IDs.

#### `identity-center/`
Responsible for:
- Identity Center groups and users.
- Permission sets and their associated policies.
- Account assignments linking groups to permission sets in individual AWS accounts.
- Configuration of HR's restricted S3 access.

### 2.2 Implementation Decisions
#### 2.2.1 Initializing IAM Identity Center
Note: The organization-integrated IAM Identity Center setup was performed manually through the AWS Management Console, in the region `us-east-1`.

The reason for manual setup is due to at the time of implementation, the available Terraform, AWS CLI, and AWS SDK workflows did not provide the initialization method needed for this organization-integrated setup. 

The only available `create-instance` operation was not a substitute for enabling Identity Center as an organization-managed service, it is meant to only setup a stand alone identity center, separate from the organization.

After initialization, Terraform references the existing Identity Center instance through data sources and manages the remaining supported resources.

This separates initial service activation from the Terraform-managed configuration.

#### 2.2.2 Identity Center Settings Management
Terraform does not currently manage every high-level Identity Center setting. Customization of the access portal URL is handled manually through the Identity Center settings page in the AWS Management Console.

The remaining supported identity and access resources are managed through Terraform.

#### 2.2.3 Account Assignments
The `aws_ssoadmin_account_assignment` resource is used to assign permission sets to the appropriate AWS accounts.

Each assignment is declared explicitly rather than using `for_each`. With two member accounts and a limited number of assignments, this approach keeps the configuration straightforward and easy to review.

For a larger environment, a data-driven model using `for_each` could reduce duplication and simplify ongoing account onboarding.

### 2.3 Stage One: AWS Organizations Foundation
The organization foundation was configured using Terraform.

Implemented components include:
- The `nimbus-cloud` AWS Organization.
- Development and production member accounts.
- DEV and PROD organizational units.
- The `NimbusOrgIamPolicy` SCP and its OU attachments.
- Outputs for member account IDs used by the Identity Center configuration.

### Implemented Organization Resources

| Resource / configuration    | Purpose                                                |
|-----------------------------|---------------------------------------------------------|
| AWS Organization            | Centralized organization-level governance               |
| Member accounts             | Separate development and production environments        | 
| DEV and PROD OUs            | Organize accounts by environment                        |
| SCP policy                  | Deny selected high-risk actions                         |
| SCP attachments             | SCP attachments                                         |
| Terraform outputs           | Expose account IDs for use in the separate Identity Center configuration|


### 2.4 Stage Two: IAM Identity Center Configuration
Four teams were configured in IAM Identity Center:
- DevOps
- Developers
- Support
- Human Resources

The implementation creates users and groups, defines permission sets, and assigns those permission sets to the appropriate AWS accounts.

### Implemented Identity and Access Configuration
The below were configured and tested.
| Team / component      | Permission set                 | Assignment      |
|-----------------------|--------------------------------|-----------------|
| DevOps                | `DevOps_Permission`            | DEV and PROD    |
| Developers            | `Developer_Crucial_Permission` | DEV             |
| Developers            | `Support_ReadOnly_Permission`  | PROD            |
| Support               | `Support_ReadOnly_Permission`  | DEV and PROD    |
| Human Resources       | `HumanResources_Permission`    | PROD only       |

The Developers' permission set provides ECR-focused access in DEV, while the shared read-only permission set restricts their production access. 

Support receives read-only access to both accounts. HR has no DEV assignment and receives only the designated report-access permissions in PROD.


### 2.5 Stage Three: HR S3 Report Access
The production account contains the manually provisioned `hr-yearly-report` S3 bucket used to demonstrate restricted access to business reports.

The bucket is a prerequisite for the HR access validation. It is created separately from the organization and Identity Center foundation.

The HR permission set allows the team to list buckets, list objects in the designated bucket, and download report objects. It does not grant upload or deletion permissions.

A relay state destination is configured to direct the HR user to the S3 console after sign-in. 

### 2.6 Deployment Prerequisites
Before deploying the configuration, ensure that the following prerequisites are satisfied:
- An AWS IAM identity with sufficient administrative permissions to create the organization, member accounts, OUs, SCPs, and Identity Center resources. This implementation used an IAM user with **AdministratorAccess**.
- Terraform and the AWS provider configured for the project.
- The S3 backend bucket already exists in the desired region.
- Each Terraform root configuration has its own **backend.tf** and intended state key.
- IAM Identity Center has been initialized manually in `us-east-1` as an organization-integrated service.
- The organization foundation has been created before the Identity Center configuration is applied.
- Member account IDs are available to the Identity Center configuration through the relevant variables.
- The `hr-yearly-report` bucket is manually created in the production account before the HR access test is performed.

### 2.7 Terraform Workflow
#### Organization Configuration
```
cd orgbootstrap
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```
Review the plan carefully before applying changes, particularly when creating member accounts or changing organization-level policies.

#### Passing Account IDs to Identity Center
The two directories are separate Terraform root configurations. Resources declared in `orgbootstrap/` cannot be referenced directly from `identity-center/`.

The current workflow supplies account IDs manually through variables. The organization configuration also exposes outputs so that the relevant IDs can be retrieved after deployment and used by the Identity Center configuration.

This keeps the configuration boundary explicit while avoiding unnecessary coupling between the two Terraform states.

#### Identity Center Configuration
After the organization foundation is available and the required account IDs have been supplied:
```
cd ../identity-center
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```
Review the plan to confirm that the intended Identity Center instance, users, groups, permission sets, and account assignments are targeted.

#### HR Bucket Prerequisite
Before validating HR access, create the `hr-yearly-report` general bucket in the production account manually. 

The bucket must exist before the HR policy can be tested against the intended resource. Ensure that the bucket is created in the correct account and Region.

---
<br>
<br>

## Chapter Three: Validation and Results
### 3.1 Validation Overview

The following tests demonstrate the intended behavior of the implemented governance and access controls. Each test identifies the objective, test action, expected result, observed result, and supporting evidence.

The tests cover successful account access, administrative guardrails, restricted S3 operations, and environment-specific permissions.

### 3.2 Validation Summary
| Test                        | Expected result                                           | Result          |
|-----------------------------|-----------------------------------------------------------|-----------------|
| IAM Identity Center sign-in | Users can access assigned accounts and permission sets    | Passed          |
| DevOps access               | AdministratorAccess is available in DEV and PROD          | Passed          |
| SCP enforcement             | Selected organization and resource operations are denied  | Passed          |
| HR S3 access                | HR can list and download designated reports in PROD       | Passed          |
| HR restricted operations    | Uploading objects and creating another bucket are denied  | Passed          |
| Developer ECR access in DEV | The developer can create an ECR repository                | Passed          |
| Developer production access | The developer cannot create an ECR repository in PROD     | Passed          |
| Support read-only access    | Support has read-only access to DEV and PROD              | Passed          |


### 3.3 Test 1: IAM Identity Center Account Access
### Objective

Verify that a user can sign in through IAM Identity Center and access the accounts assigned to their group.

#### Test action

Sign in as `jmayer`, a member of the DevOps team, and inspect the available accounts and permission sets.

#### Expected result

The user can access both Nimbus Development and Nimbus Production with the `DevOps_Permission` permission set.

#### Observed result

The user could access both assigned accounts with administrative permissions.

### Evidence
!["Devops Permission"](/Docs/Screenshots/evidence/DevOps_Perm.png)

### 3.4 Test 2: Service Control Policy Enforcement
#### Objective

Verify that the organization-level guardrails deny selected organization operations, even when the user has broad administrative permissions in a member account.

#### Test action

Use the DevOps user's administrative access to attempt a restricted organization operation covered by the SCP.
**Example:** Attempt to leave the Organization

The relevant statement includes:
```
statement {
  sid    = "DenyLeavingTheOrganizationAndOU"
  effect = "Deny"

  actions = [
    "organizations:DeleteOrganization",
    "organizations:LeaveOrganization",
    "organizations:MoveAccount"
  ]

  resources = ["*"]
}
```
#### Expected result

The restricted operation is denied within the applicable SCP scope.

#### Observed result

The attempt to leave the organization was denied when tested using DevOps access.

#### Evidence
!["SCP in action"](/Docs/Screenshots/evidence/Scp_Devops.png)

The policy also includes deny statements for selected CloudTrail, S3, ECR, and EKS operations. These controls are intended to reduce the risk of privileged users disabling logging or deleting selected resources.

### 3.5 Test 3: Human Resources S3 Access
#### Objective

Verify that HR can retrieve designated reports from the production S3 bucket without receiving broad AWS access or permission to upload or delete objects.

#### Test action

Sign in as `rmarcus`, the HR demonstration user. Navigate to the S3 console through the configured relay state, list the designated bucket, and download an existing report. Then attempt to upload an object and create a separate bucket.

#### Expected result

The user can list buckets, list objects in `hr-yearly-report`, and download permitted reports. Uploading objects and creating an additional bucket are denied.

#### Observed result

HR could access the intended report location and download reports. The attempted upload and bucket creation were denied.

#### Evidence
HR permission assignment:
!["HR access portal"](/Docs/Screenshots/evidence/Hr_Perm.png)

S3 relay state:
!["HR Relay State"](/Docs/Screenshots/evidence/Relay_Hr.png)

Denied operations:
!["HR Denied access"](/Docs/Screenshots/evidence/Hr_Scp.png)
!["HR Denied access"](/Docs/Screenshots/evidence/Hr_Scp2.png)

### 3.6 Test 4: Developer ECR Access in DEV and PROD
#### Objective

Verify that Developers can create ECR repositories in the development account but cannot perform the same operation in production.

#### Test action

Sign in as `lvance`, a member of the Developers team. Attempt to create an ECR repository in Nimbus Development account, then repeat the operation in Nimbus Production account.

#### Expected result

The development operation succeeds under `Developer_Crucial_Permission`. The production operation is denied under `Support_ReadOnly_Permission`.

#### Observed result

The developer could create an ECR repository in DEV. The equivalent repository-creation attempt was denied in PROD.

#### Evidence

Developer permission assignments:
!["Developer access Portal"](/Docs/Screenshots/evidence/Dev_Perm.png)

ECR relay state:
!["Developer Relay State"](/Docs/Screenshots/evidence/Relay_Developer.png)

Successful ECR repository creation in DEV:
!["Developer Ecr access"](/Docs/Screenshots/evidence/Develop_ecr_dev.png)

Denied ECR repository creation in PROD:
!["Developer readonly"](/Docs/Screenshots/evidence/Develop_Perm2.png)

### 3.7 Test 5: Support Read-Only Access
#### Objective

Verify that Support has read-only access to both development and production accounts.

#### Test action

Sign in as `zparker`, a member of the Support team, and inspect the assigned permission set and available operational console access.

#### Expected result

The user has `Support_ReadOnly_Permission` in both accounts and cannot perform actions that require additional write permissions.

#### Observed result

The Support user could access the assigned accounts with read-only permissions and was directed to the CloudWatch console through relay state.

#### Evidence

Support permission assignments:
!["Support Access Portal"](/Docs/Screenshots/evidence/Support_Perm.png)

CloudWatch relay state:
!["Support Relay"](/Docs/Screenshots/evidence/Relay_Support.png)

### 3.8 Limitations and Future Improvements

#### Limitatiion
As a demonstration of AWS Organizations and IAM Identity Center, this project focuses on foundational multi-account governance, organizational structure, Service Control Policies (SCPs), and team-based access management. The current implementation has the following limitations:

- **No centralized logging and security account:** The architecture does not include a dedicated account for centralized log collection, security monitoring, and audit activities.
- **No AWS Control Tower integration:** Account governance is implemented directly through AWS Organizations and Terraform rather than through an orchestration framework such as AWS Control Tower.
- **No workload deployment roles:** The project does not yet implement dedicated federated IAM roles for automated infrastructure and application deployments across the development and production accounts.
- **Limited centralized compliance visibility:** The environment does not include a centralized dashboard for reviewing compliance status across member accounts.
- **No external identity provider integration:** Workforce access relies on IAM Identity Center without integration with an external identity provider for federated authentication.
- **No centralized observability architecture:** CloudWatch monitoring, log aggregation, and operational visibility have not been consolidated into a dedicated monitoring account.

#### Future Improvements
The following improvements would extend the current implementation toward a more comprehensive enterprise AWS governance architecture:
- **Establish a centralized logging and security account:** Introduce a dedicated member account for collecting and retaining audit logs, centralizing security findings, and supporting security investigations across the organization.
- **Evaluate AWS Control Tower:** Integrate AWS Control Tower to simplify account provisioning, establish landing-zone guardrails, and standardize governance across organizational accounts.
- **Implement federated workload deployment roles:** Configure IAM roles using OpenID Connect (OIDC) federation for CI/CD pipelines, enabling controlled and auditable deployments into development and production without relying on long-lived AWS access keys.
- **Centralize compliance monitoring:** Use AWS Control Tower, AWS Config, and organization-wide aggregation where appropriate to improve compliance visibility, identify non-compliant resources, and monitor configuration changes across accounts.
- **Integrate an external identity provider:** Connect IAM Identity Center to an external identity provider to support centralized workforce authentication, single sign-on, and streamlined user lifecycle management.
- **Introduce centralized observability:** Establish a dedicated monitoring account or centralized monitoring architecture for CloudWatch metrics, logs, alarms, and dashboards, improving operational visibility across the organization.



### 3.9 Cleanup and Resource Lifecycle
This project uses Terraform to manage the organization foundation and Identity Center configuration. However, **the entire environment cannot be safely removed by running terraform destroy indiscriminately**.

The AWS Organization resource is protected with prevent_destroy = true to reduce the risk of accidental organization deletion.
```
lifecycle {
  prevent_destroy = true
}
```
Service Control Policies are enabled for the organization through the `SERVICE_CONTROL_POLICY` policy type. This setting enables SCP functionality; it does not itself define the policy statements or attachments.

Other resources, including organizational units, SCPs and their attachments, Identity Center resources, and the HR bucket configuration, may be eligible for Terraform destruction according to their dependencies and lifecycle settings.

The member accounts and organization require special attention during cleanup. The organization resource's lifecycle protection must be addressed deliberately, and account closure or removal may require additional steps outside the normal Terraform destruction workflow.

Before cleaning up:
1. Review the Terraform state and the resources managed by each root configuration.
2. Inspect terraform plan -destroy where appropriate, without automatically applying the plan.
3. Account for SCP attachments and other dependencies before removing governance resources.
4. Follow the applicable AWS procedures for closing or removing member accounts.
5. Handle the organization lifecycle protection deliberately and verify the consequences before attempting organization deletion.

> [Disclaimer]
> This is a portfolio project using a fictional company scenario. It demonstrates selected AWS governance and identity-management patterns and is not intended to represent a complete production landing zone or a universal security baseline. Production implementations should be adapted to business requirements, risk, compliance obligations, and operational processes.
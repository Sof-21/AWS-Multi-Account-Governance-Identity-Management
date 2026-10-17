# Nimbus Cloud:  AWS Multi-Account Governance & Identity Management
<br>

# Chapter One: Design and Architecture

## Overview

This project demonstrates how a cloud engineer can design and implement a governed, multi-account AWS environment using **AWS Organizations**, **AWS IAM Identity Center**, and **Terraform**.

The project is presented as a fictional engineering engagement for **Nimbus Cloud**, a company that needs to separate development and production workloads, apply organization-wide security guardrails, and manage employee access centrally.

The implementation is intended to demonstrate practical cloud engineering skills, infrastructure as code, identity and access management, and security-conscious design.

> **Project note:** Nimbus Cloud is a fictional company used to frame the technical scenario. This repository documents a portfolio/lab implementation.

## Business Scenario

Nimbus Cloud is growing and now operates multiple AWS accounts. Its teams need access to cloud resources to perform their daily responsibilities, but access must be controlled consistently across development and production environments.

The company has asked us to establish a foundational AWS governance and identity-management model that:

- Organizes AWS accounts into clear development and production environments.
- Establishes security guardrails through Service Control Policies (SCPs).
- Centralizes workforce access using AWS IAM Identity Center.
- Uses groups and permission sets to align access with team responsibilities.
- Applies least-privilege principles, particularly for production access and sensitive HR reports.
- Manages the configuration with Terraform so it can be reviewed, version-controlled, and reproduced.

## Objectives

1. **Establish AWS Organizations** and organize member accounts under `DEV` and `PROD` organizational units (OUs).
2. **Apply SCP guardrails** to restrict selected high-risk actions across the organization or relevant OUs.
3. **Configure IAM Identity Center** for centralized workforce access.
4. **Create four teams** in Identity Center: DevOps, Developers, Support, and Human Resources.
5. **Define permission sets and account assignments** based on each team's responsibilities.
6. **Implement the configuration using Terraform**, keeping organization bootstrap and Identity Center configuration logically separated.
7. **Validate access controls** by testing both permitted and denied actions.
8. **Document deployment, security considerations, limitations, and cleanup procedures.**

## Proposed Architecture

![Nimbus Cloud AWS Goverance](/Docs/Screenshots/repoImages/Nimbus%20Cloud%20AWS%20Governance.png)

## Team Access Model
The final permissions should reflect the permission sets, policies, and account assignments as planned.

| Team | DEV account | PROD account | Access rationale |
|---|---|---|---|
| DevOps | Administrative access  | Administrative access | Operate and maintain cloud infrastructure |
| Developers | Development Crucial permissions | Read-only access | Build and test in DEV while limiting production changes |
| Support | Read-only operational access | Read-only operational access | Monitor Infra and Investigate issues without routine write access |
| Human Resources | Access to designated HR reports in S3 | Access to designated HR reports in S3 | Retrieve approved reports without broad AWS access |


## Technology Stack


- **Amazon Web Services (AWS)**
  - AWS Organizations
  - AWS Organizations Service Control Policies (SCPs)
  - AWS IAM Identity Center
  - AWS IAM policies and permission sets
- **Terraform** — Infrastructure as Code (IaC)
- **Git** — Version control and change tracking

<p align="center">
  <img src="https://skillicons.dev/icons?i=terraform,aws,git" />
</p>


## Repository Structure

The Terraform configurations are separated by responsibility. The exact file names may change as the project develops.

```text
.
├── orgbootstrap/
│   ├── providers.tf
│   ├── organizations.tf
│   ├── accounts.tf
│   ├── organizational_units.tf
│   ├── scp.tf
|   ├── backend.tf
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
|   ├── outputs.tf
│   └── variables.tf
│
└── README.md
```


### `orgbootstrap/`

Responsible for the AWS Organizations foundation, including:

- Organization configuration and account membership.
- `DEV` and `PROD` OUs.
- SCP definitions and attachments.
- Outputs needed by other configurations, such as member account IDs.

### `identity-center/`

Responsible for workforce identity and access, including:

- Identity Center groups and users.
- Permission sets and their associated policies.
- Account assignments connecting groups to permission sets in individual AWS accounts.


## State and Configuration Boundaries

Each directory is intended to be operated as a separate Terraform root configuration. Resources declared in one root configuration cannot be referenced directly from another. Values such as account IDs must be passed through variables, outputs.

## Security Design Considerations

- **Least privilege:** Grant only the permissions required for each team's responsibilities.
- **Production access:** Avoid broad production write access unless the business requirement justifies it; consider controlled elevation for sensitive operations.
- **SCP behavior:** SCPs define maximum available permissions for affected principals in member accounts. They do not grant permissions by themselves, and they do not restrict principals in the management account in the same way they restrict member accounts.
- **Management account protection:** Keep administrative access tightly controlled and take care when applying organization-wide policies.
- **S3 access:** `s3:ListAllMyBuckets` allows a user to list bucket names in the account; it does not limit the returned names to a single bucket. Bucket listing and object access require their own appropriately scoped permissions.
- **Terraform state:** State files may contain sensitive information. Restrict access and use appropriate storage and locking practices if remote state is configured.
- **Credentials:** Avoid committing access keys, secret values, private keys, or state files to version control.
- **Testing:** Validate both allowed and denied actions rather than assuming a policy behaves as intended.

<br>
<br>
<br>

# Chapter Two: Implementation

> **Status note:** This chapter separates the intended implementation workflow from the actual configuration. Replace planned items with the resources, policies, assignments, and decisions that are present in the repository. Do not describe a planned feature as completed until it has been implemented.

## Implementation Overview

The Terraform configuration is separated into two root configurations so that organization-level governance and workforce identity management can be managed independently:

- `orgbootstrap/` — AWS Organizations, member accounts, OUs, SCPs, and relevant outputs.
- `identity-center/` — Identity Center groups and users, permission sets, policies, and account assignments.

Document the actual resources created in each directory below.

## Stage 1 — AWS Organizations Foundation

Record the implemented configuration:

- Organization configuration and account membership.
- Member accounts created or invited.
- `DEV` and `PROD` organizational units.
- The account placement within each OU.
- SCPs created, their attachment targets, and the actions they restrict.
- Outputs used to make account IDs available to the Identity Center configuration.

### Implemented Organization Resources

| Resource or configuration | What it does | Actual status / notes |
|---|---|---|
| AWS Organization | Provides centralized organization-level governance | Update with actual result |
| Member accounts | Separate development and production environments | Update with actual account setup; do not publish sensitive account details unnecessarily |
| `DEV` and `PROD` OUs | Organize accounts by environment | Update with actual result |
| SCPs and attachments | Restrict selected actions within their target scope | List each implemented policy and attachment |

For each SCP, document its purpose, where it is attached, and how its behavior was tested. Remember that an SCP restricts the maximum permissions available; it does not grant permissions.

## Stage 2 — IAM Identity Center Configuration

Record the groups, users, permission sets, policies, and account assignments that have actually been configured.

The intended teams are:

- DevOps
- Developers
- Support
- Human Resources

### Implemented Identity and Access Configuration

| Team / component | Intended configuration | Actual status / notes |
|---|---|---|
| DevOps | Appropriate elevated permissions in the assigned accounts | Update with permission set and account assignments |
| Developers | Development access and restricted or read-only production access | Update with permission set and account assignments |
| Support | Read-only operational access | Update with permission set and account assignments |
| Human Resources | Restricted access to designated HR reports in S3, where configured | Update with policy and account assignments |
| Users and groups | Test identities grouped by responsibility | Record what has actually been created |
| Account assignments | Connect a group and permission set to a specific AWS account | Record the actual assignments |

Identity Center account assignments target individual AWS accounts. A group that needs access to multiple accounts needs a separate assignment for each target account.

## Stage 3 — HR S3 Report Access

If the HR S3 use case is implemented, document the exact bucket purpose and the policy permissions.

The intended access pattern is to allow HR users to list and download approved reports without granting broad AWS access. Document:

- The bucket used for the demonstration.
- Whether users can list the bucket and its objects.
- Whether users can download objects.
- Whether upload and delete operations are intentionally not allowed.
- Any additional policies or permission-set settings that affect the final permissions.

Do not include sensitive report contents, credentials, or other confidential information in the repository.

## Terraform Workflow

The commands below are a high-level workflow. Confirm the provider configuration, backend settings, variables, AWS credentials, and current Terraform state before running them.

### Organization configuration

```bash
cd orgbootstrap
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the plan carefully before applying changes. Apply only after confirming that the planned changes target the intended organization and accounts.

### Identity Center configuration

After the organization foundation is configured and the required account IDs are available:

```bash
cd ../identity-center
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the plan and confirm that it targets the intended Identity Center instance, groups, permission sets, and accounts before applying.

### Account ID and State Sharing

Because these are separate Terraform root configurations, the Identity Center configuration cannot directly reference a resource declared in `orgbootstrap`. Account IDs must be supplied through variables, outputs and an appropriate state-sharing mechanism, or another controlled configuration interface.

If remote state is used, ensure that access to the state object is appropriately restricted.

### Operational Caution

Account creation, organization changes, and Identity Center assignments can have consequences beyond a disposable lab. Do not assume that a single `terraform destroy` is appropriate or safe for every resource. Review the plan and dependencies before making destructive changes.

---

# Chapter Three — Validation and Results

## Validation Approach

Validation should demonstrate that the configured governance and access controls behave as intended. Test both permitted and denied actions. Record the actual outcome and supporting evidence; do not mark a test as successful until it has been performed.

## Validation Results

| Test | Expected result | Status / evidence |
|---|---|---|
| User signs in through IAM Identity Center | User can access assigned accounts | TODO — record actual result |
| DevOps accesses DEV | Access matches the DevOps permission set | TODO — record actual result |
| DevOps accesses PROD | Access matches the approved production model | TODO — record actual result |
| Developer attempts a restricted production action | Action is denied | TODO — record actual result |
| Support only have ReadOnlyAccess | Action is denied | TODO — record actual result |
| HR lists and downloads an approved report | Access is allowed as designed | TODO — record actual result |
| HR attempts to upload or delete an object | Action is denied if not granted elsewhere | TODO — record actual result |
| SCP guardrail is tested | Restricted action is denied in the intended scope | TODO — record actual result |

For each test, capture concise evidence such as the relevant console result, CLI output, or a screenshot. Remove credentials, personal information, and sensitive account details before publishing evidence.

## Validation Evidence

The following tests demonstrate that the implemented AWS governance and identity-management controls behave as expected. Each test includes evidence of the configuration or observed result.

### Test 1 — IAM Identity Center Account Access

**Objective:** Verify that a user can sign in through IAM Identity Center and access the AWS accounts assigned to their group.

**Expected result:** The user can access the intended AWS account and sees the appropriate permission set.

**Result:** Passed — update with your actual test result.

> Screenshot here
### Test 2 — Service Control Policy Enforcement

Objective: Verify that an SCP prevents a restricted action within its intended scope.

Expected result: The action is denied even if the user has an IAM permission that would otherwise allow it.

Result: Passed — update with your actual test result.

> Screenshot here

### Test 3 — Human Resources S3 Access

Objective: Verify that the HR user can retrieve approved reports without receiving unnecessary permissions.

Expected result: The user can list or download permitted reports, while unauthorized operations are denied.

Result: Passed — update with your actual test result.

> Screenshot here

## Limitations and Future Improvements

Update this section as the implementation evolves. Potential future improvements include:

- Use a more data-driven Terraform model for group-to-account assignments.
- Improve account onboarding so new accounts receive the intended governance and access configuration.
- Add automated validation and policy checks to the workflow.
- Add stronger state-management protections, including state versioning where appropriate.
- Introduce a controlled process for privileged production access.
- Expand the validation evidence and document operational recovery procedures.

Keep only items that are still future work. Move completed improvements into Chapter Two and document their validation in this chapter.

## Cleanup

Review the resources and their dependencies before removing anything. Do not remove the organization, member accounts, or management-account resources casually. Some resources may require manual intervention or have lifecycle restrictions.

For disposable resources created specifically for testing, use the relevant Terraform configuration and review its destruction plan before proceeding. Preserve any state or configuration information needed for future management.

## Disclaimer

This is a portfolio project using a fictional company scenario. It demonstrates selected AWS governance and identity-management patterns; it is not intended to represent a complete production landing zone or a universal security baseline. Actual production designs should be adapted to business requirements, risk, compliance obligations, and operational processes.

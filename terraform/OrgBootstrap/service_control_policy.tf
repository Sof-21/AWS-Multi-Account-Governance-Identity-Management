# The actual iam policy document

data "aws_iam_policy_document" "NimbusOrgIamPolicy" {

  # A statement to restrict member accounts from leaving the organization
  statement {
    sid    = "DenyLeavingTheOrganization"
    effect = "Deny"
    actions = [
      "organizations:DeleteOrganization",
      "organizations:LeaveOrganization"
    ]
    resources = ["*"]
  }

  # A statement to deny deletion of specific resources, can be reviewed and expanded further.
  statement {
    sid    = "DenyDeletionOfSelectedResources"
    effect = "Deny"
    actions = [
      "cloudtrail:DeleteDashboard",
      "cloudtrail:DeleteChannel",
      "cloudtrail:DeleteResourcePolicy",
      "cloudtrail:DeleteTrail",
      "cloudtrail:DeleteEventDataStore",
      "cloudtrail:StopLogging",
      "cloudtrail:StopImport",
      "s3:DeleteBucket",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:DeleteBucketPolicy",
      "ecr:DeleteRepository",
      "ecr:DeleteLifecyclePolicy",
      "eks:DeleteCluster",
      "eks:DeleteFargateProfile",
      "eks:DeleteNodegroup"

    ]
    resources = ["*"]
  }

}


# The Organizations Policy using the above Iam document
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
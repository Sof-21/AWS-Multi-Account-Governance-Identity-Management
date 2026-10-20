
# permission set for Human Resources team.
resource "aws_ssoadmin_permission_set" "HumanResource_permission_set" {
  name             = "HumanResources_Permission"
  instance_arn     = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  relay_state      = "https://s3.console.aws.amazon.com/s3/home?region=us-east-1#" # The URL to redirect to after login to s3 page
  session_duration = "PT8H"                                                        # The duration of the session for HR team - 8 hours
}

data "aws_iam_policy_document" "HR_Policy" {
  statement {
    sid    = "HRS3ListAllBuckets"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "HRS3ListHRBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::hr-yearly-report",
    ]
  }

  statement {
    sid    = "HRS3DownloadHRFiles"
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::hr-yearly-report/*",
    ]
  }
}


resource "aws_ssoadmin_permission_set_inline_policy" "HRPolicyDoc" {
  inline_policy      = data.aws_iam_policy_document.HR_Policy.json
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.HumanResource_permission_set.arn

}

# HR Permission set assignment to HR group
resource "aws_ssoadmin_account_assignment" "HR-group-assignment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.HumanResource_permission_set.arn

  principal_id   = aws_identitystore_group.HumanResources.group_id # HR group ID
  principal_type = "GROUP"

  target_id   = var.prod-account-id # Prod account ID, no dev account assignment for HR team.
  target_type = "AWS_ACCOUNT"
}


# ------------


# ------------
# Devops Permission sets - uses aws managed AdministratorAccess policy

resource "aws_ssoadmin_permission_set" "DevOps_permission_set" {
  name             = "DevOps_Permission"
  instance_arn     = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  relay_state      = "https://console.aws.amazon.com/eks/home?region=us-east-1#/clusters" # The URL to redirect to after login to eks page
  session_duration = "PT8H"                                                               # The duration of the session for DevOps team - 8 hours
}

resource "aws_ssoadmin_managed_policy_attachment" "DevopsPolicy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.DevOps_permission_set.arn
}

# Devops Permission set assignment to DevOps group
resource "aws_ssoadmin_account_assignment" "DevOps-group-prod-assignment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.DevOps_permission_set.arn

  principal_id   = aws_identitystore_group.DevOps.group_id # DevOps group ID
  principal_type = "GROUP"

  target_id   = var.prod-account-id # Prod account ID
  target_type = "AWS_ACCOUNT"

}

resource "aws_ssoadmin_account_assignment" "DevOps-group-dev-assignment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.DevOps_permission_set.arn

  principal_id   = aws_identitystore_group.DevOps.group_id # DevOps group ID
  principal_type = "GROUP"

  target_id   = var.dev-account-id # Dev account ID
  target_type = "AWS_ACCOUNT"

}

# ---------------




#----------------

# Support Permission sets - uses aws managed ReadOnlyAccess policy
resource "aws_ssoadmin_permission_set" "Support_permission_set" {
  name             = "Support_ReadOnly_Permission"
  instance_arn     = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  session_duration = "PT8H"                                                             # The duration of the session for Support team - 8 hours
  relay_state      = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#" # url to redirect to cloudwatch for support to monitor
}

resource "aws_ssoadmin_managed_policy_attachment" "SupportPolicy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.Support_permission_set.arn
}


# Support Permission set assignment to support group
resource "aws_ssoadmin_account_assignment" "Support-group-prod-assignment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.Support_permission_set.arn

  principal_id   = aws_identitystore_group.Support.group_id # Support group ID
  principal_type = "GROUP"

  target_id   = var.prod-account-id # Prod account ID
  target_type = "AWS_ACCOUNT"

}

resource "aws_ssoadmin_account_assignment" "Support-group-dev-assignment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.Support_permission_set.arn

  principal_id   = aws_identitystore_group.Support.group_id # Support group ID
  principal_type = "GROUP"

  target_id   = var.dev-account-id # Dev account ID
  target_type = "AWS_ACCOUNT"

}

#------------------


#-------------------
# Developers Permission sets - uses aws managed AmazonEC2ContainerRegistryPowerUser policy
resource "aws_ssoadmin_permission_set" "Developer_crucial_permission_set" {
  name             = "Developer_Crucial_Permission"
  instance_arn     = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  relay_state      = "https://console.aws.amazon.com/ecr/home?region=us-east-1#" # The URL to redirect to after login to ecr page
  session_duration = "PT8H"                                                      # The duration of the session for Developer team - 8 hours
}


# Created inline policy for developers as the managed permission does not allow creation of ecr repo.
data "aws_iam_policy_document" "Dev_Ecr_Policy" {
  statement {
    sid    = "AllowEcrRepoCreation"
    effect = "Allow"

    actions = [
      "ecr:CreateRepository",
    ]

    resources = ["*"]
  }


}

resource "aws_ssoadmin_permission_set_inline_policy" "DevInlinePolicyDoc" {
  inline_policy      = data.aws_iam_policy_document.Dev_Ecr_Policy.json
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.Developer_crucial_permission_set.arn

}

resource "aws_ssoadmin_managed_policy_attachment" "DeveloperCrucialPolicy" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  permission_set_arn = aws_ssoadmin_permission_set.Developer_crucial_permission_set.arn
}




# Developers Permission set assignment to DevOps group
resource "aws_ssoadmin_account_assignment" "Developers-group-prod-assignment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.Support_permission_set.arn # Devs will have readonly access to production like support.

  principal_id   = aws_identitystore_group.Developer.group_id # Developers group ID
  principal_type = "GROUP"

  target_id   = var.prod-account-id # Prod account ID
  target_type = "AWS_ACCOUNT"

}

resource "aws_ssoadmin_account_assignment" "Developer-group-dev-assignment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.Developer_crucial_permission_set.arn

  principal_id   = aws_identitystore_group.Developer.group_id # Developers group ID
  principal_type = "GROUP"

  target_id   = var.dev-account-id # Dev account ID
  target_type = "AWS_ACCOUNT"

}
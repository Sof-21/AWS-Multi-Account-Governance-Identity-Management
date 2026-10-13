
# Member accounts to be enrolled into the OU

# Dev account
resource "aws_organizations_account" "nimbus-dev-account" {
  name                       = "Nimbus Development Account"
  email                      = "dev-nimbus@proton.me"
  iam_user_access_to_billing = "ALLOW" # this blocks access to iam users to observe billing data in the member account
  parent_id                  = aws_organizations_organizational_unit.nimbus-dev.id
}

# Prod account
resource "aws_organizations_account" "nimbus-prod-account" {
  name                       = "Nimbus Production Account"
  email                      = "nimbus-prod@proton.me"
  iam_user_access_to_billing = "ALLOW" # this blocks access to iam users to observe billing data in the member account
  parent_id                  = aws_organizations_organizational_unit.nimbus-prod.id
}



# Group creation for All 4 teams.
resource "aws_identitystore_group" "Developer" {
  display_name      = "Developer"
  description       = "Developer group"
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]
}

# HR Group Creation
resource "aws_identitystore_group" "HumanResources" {
  display_name      = "Human Resources"
  description       = "Human Resources group"
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]
}

# Support Group Creation
resource "aws_identitystore_group" "Support" {
  display_name      = "Support"
  description       = "Support group"
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]
}

# DevOps Group Creation
resource "aws_identitystore_group" "DevOps" {
  display_name      = "DevOps"
  description       = "DevOps group"
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]
}
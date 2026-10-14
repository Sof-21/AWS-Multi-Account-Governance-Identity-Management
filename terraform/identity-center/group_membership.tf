
# Adding users to created groups
resource "aws_identitystore_group_membership" "Developer-membership" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]
  group_id          = aws_identitystore_group.Developer.group_id
  member_id         = aws_identitystore_user.LeoVance.user_id
}

resource "aws_identitystore_group_membership" "HumanResources-membership" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]
  group_id          = aws_identitystore_group.HumanResources.group_id
  member_id         = aws_identitystore_user.RachelMarcus.user_id
}

resource "aws_identitystore_group_membership" "Support-membership" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]
  group_id          = aws_identitystore_group.Support.group_id
  member_id         = aws_identitystore_user.ZackParker.user_id
}
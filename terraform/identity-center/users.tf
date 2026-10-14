# Creating a developer user
resource "aws_identitystore_user" "LeoVance" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]

  display_name = "Leo Vance"
  user_name    = "lvance"

  name {
    given_name  = "Leo"
    family_name = "Vance"
  }

  emails {
    value = "lvance@nimbus.proton.me"
  }

  title = "Software Engineer"
}


# Creating a Human Resource user
resource "aws_identitystore_user" "RachelMarcus" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]

  display_name = "Rachel Marcus"
  user_name    = "rmarcus"

  name {
    given_name  = "Rachel"
    family_name = "Marcus"
  }

  emails {
    value = "rmarcus@nimbus.proton.me"
  }

  title = "Human Resources Manager"
}


# Creating a Support user
resource "aws_identitystore_user" "ZackParker" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]

  display_name = "Zack Parker"
  user_name    = "zparker"

  name {
    given_name  = "Zack"
    family_name = "Parker"
  }

  emails {
    value = "zparker@nimbus.proton.me"
  }

  title = "Support Engineer"
}
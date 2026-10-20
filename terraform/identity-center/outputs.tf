# identity center outputs.

# Permission set outputs.
output "Dev-permission-set" {
  value       = aws_ssoadmin_permission_set.Developer_crucial_permission_set.name
  description = "The name of the developer permission set"
}

output "DevOps-permission-set" {
  value       = aws_ssoadmin_permission_set.DevOps_permission_set.name
  description = "The name of the DevOps permission set"
}

output "HR-permission-set" {
  value       = aws_ssoadmin_permission_set.HumanResource_permission_set.name
  description = "The name of the HR permission set"
}

output "Support-permission-set" {
  value       = aws_ssoadmin_permission_set.Support_permission_set.name
  description = "The name of the Support permission set"
}


# Created groups outputs.
output "Developers-group" {
  value       = aws_identitystore_group.Developer.display_name
  description = "The name of the Developers group"
}

output "DevOps-group" {
  value       = aws_identitystore_group.DevOps.display_name
  description = "The name of the DevOps group"
}

output "HR-group" {
  value       = aws_identitystore_group.HumanResources.display_name
  description = "The name of the HR group"
}

output "Support-group" {
  value       = aws_identitystore_group.Support.display_name
  description = "The name of the Support group"
}


# Created user accounts. 
output "HR-user-account" {
  value       = aws_identitystore_user.RachelMarcus.user_name
  description = "The name of the HR user account"
}

output "Dev-user-account" {
  value       = aws_identitystore_user.LeoVance.user_name
  description = "The name of the Developer user account"
}

output "DevOps-user-account" {
  value       = aws_identitystore_user.JohnMayer.user_name
  description = "The name of the DevOps user account"
}

output "Support-user-account" {
  value       = aws_identitystore_user.ZackParker.user_name
  description = "The name of the Support user account"
}
output "Dev-account-id" {
  value       = aws_organizations_account.nimbus-dev-account.id
  description = "The account id of the development account"
  depends_on  = [aws_organizations_organization.nimbus-cloud]
}

output "Prod-account-id" {
  value       = aws_organizations_account.nimbus-prod-account.id
  description = "The account id of the production account"
  depends_on  = [aws_organizations_organization.nimbus-cloud]
}

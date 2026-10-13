# Create organization units for dev and prod accounts

# Dev Account Organizational Unit
resource "aws_organizations_organizational_unit" "nimbus-dev" {
  name      = "Nimbus Development"
  parent_id = aws_organizations_organization.nimbus-cloud.id
}

# Prod account Organizational Unit
resource "aws_organizations_organizational_unit" "nimbus-prod" {
  name      = "Nimbus Production"
  parent_id = aws_organizations_organization.nimbus-cloud.id
}
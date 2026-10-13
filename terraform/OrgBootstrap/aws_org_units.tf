# Create organization units for dev and prod accounts

# Dev Account Organizational Unit
resource "aws_organizations_organizational_unit" "nimbus-dev-ou" {
  name      = "Nimbus Development Organizational Unit"
  parent_id = aws_organizations_organization.nimbus-cloud.id
}

# Prod account Organizational Unit
resource "aws_organizations_organizational_unit" "nimbus-prod-ou" {
  name      = "Nimbus Production Organizational Unit"
  parent_id = aws_organizations_organization.nimbus-cloud.id
}
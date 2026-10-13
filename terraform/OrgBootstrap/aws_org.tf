resource "aws_organizations_organization" "nimbus-cloud" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com", # allow organization wide cloud trail
    "config.amazonaws.com",     # allow organization wide configuration for future use.
    "sso.amazonaws.com"         # allow iam identity center for centralized identity management
  ]

  feature_set = "ALL"

  # protection against accidental tf destroy
  lifecycle {
    prevent_destroy = true
  }
}

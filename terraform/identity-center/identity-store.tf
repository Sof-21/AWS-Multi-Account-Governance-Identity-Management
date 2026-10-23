
# Data source for AWS SSO Admin instances
data "aws_ssoadmin_instances" "nimbus-identity-center" {}

# Output the ARN of the SSO instance which was manually configured
output "arn" {
  value = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
}

# Output the Identity Store ID of the SSO instance which was manually configured
output "identity_store_id" {
  value = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]
}

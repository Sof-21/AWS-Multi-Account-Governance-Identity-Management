data "aws_ssoadmin_instances" "nimbus-identity-center" {}

output "arn" {
  value = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.arns)[0]
}

output "identity_store_id" {
  value = tolist(data.aws_ssoadmin_instances.nimbus-identity-center.identity_store_ids)[0]
}

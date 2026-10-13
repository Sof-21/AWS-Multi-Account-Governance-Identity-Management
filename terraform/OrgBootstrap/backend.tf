terraform {
  backend "s3" {
    bucket       = "sof-terraform-projects-states"
    key          = "aws-multi-account-governance-identity-management/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}

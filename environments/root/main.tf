terraform {
  backend "s3" {
    bucket         = "clouduru-terraform-state"
    dynamodb_table = "clouduru-terraform-locks"
    key            = "root/terraform.tfstate"
    region         = "eu-west-1"
  }
}


provider "aws" {
  version = "~> 3.40.0"
  region  = "eu-west-1"
}


module "terraform_state" {
  bucket_name = "clouduru-terraform-state"
  lock_table_name = "clouduru-terraform-locks"
  source = "../../modules/terraform-state"
}

# -------
# Sandbox
# -------

# Create the organization account
resource "aws_organizations_account" "sandbox" {
  name  = "sandboxduru"
  email = "andrei.petric90+sandboxduru@gmail.com"

  # Enables IAM users to access account billing information
  # if they have the required permissions
  iam_user_access_to_billing = "ALLOW"
}

# Policy for assuming the admin role in the sandbox account
resource "aws_iam_policy" "sandbox_admin" {
  name        = "SandboxAdminPolicy"
  description = "Allow admin access to sandbox account"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = "arn:aws:iam::${aws_organizations_account.sandbox.id}:role/OrganizationAccountAccessRole"
      }
    ]
  })
}

# Attach policy to andrei
resource "aws_iam_user_policy_attachment" "sandbox_admin" {
  user       = "andrei"
  policy_arn = aws_iam_policy.sandbox_admin.arn
}

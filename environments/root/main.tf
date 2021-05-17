terraform {
  backend "s3" {
    bucket = "clouduru-terraform-state"
    dynamodb_table = "clouduru-terraform-locks"
    key    = "root/terraform.tfstate"
    region = "eu-west-1"
  }
}


provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "clouduru-terraform-state"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "clouduru-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
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
    }]
  })
}

# Attach policy to andrei
resource "aws_iam_user_policy_attachment" "sandbox_admin" {
  user       = "andrei"
  policy_arn = aws_iam_policy.sandbox_admin.arn
}

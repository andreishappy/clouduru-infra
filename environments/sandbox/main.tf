provider "aws" {
  version = "~> 3.40.0"
  region  = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::541742792673:role/OrganizationAccountAccessRole"
  }
}

terraform {
  backend "s3" {
    bucket         = "clouduru-sandbox-terraform-state"
    dynamodb_table = "clouduru-sandbox-terraform-state"
    key            = "root/terraform.tfstate"
    region         = "eu-west-1"
    role_arn       = "arn:aws:iam::541742792673:role/OrganizationAccountAccessRole"
  }
}

module "terraform_state" {
  bucket_name     = "clouduru-sandbox-terraform-state"
  lock_table_name = "clouduru-sandbox-terraform-state"
  source          = "../../modules/terraform-state"
}

module "nest_js_poc" {
  source = "../../modules/nest-js-poc"
}

output "ecr_repository_url" {
  value = module.nest_js_poc.ecr_repository_url
}

output "public_url" {
  value = module.nest_js_poc.public_url
}
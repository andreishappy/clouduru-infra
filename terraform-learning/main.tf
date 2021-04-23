terraform {
  backend "s3" {
    bucket = "terraform-learning-terraform-state"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-learning-locks"
    encrypt        = true
  }
}

module "hello_world" {
  source          = "../modules/hello-world/"
  resource_prefix = "terraform-learning"
}

output "elb_dns" {
  value = module.hello_world.elb_dns_name
}
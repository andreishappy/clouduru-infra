# Terraform Learning

I use this repo to learn terraform

# AWS auth

To do AWS auth we use [aws-vault](https://github.comy99designs/aws-vault) to store credentials locally securely.

Please configure a `terraform-learning` profile with an AWS access key from the AWS console.

In order to run any terraform `<command>`, run

```
aws-vault exec terraform-learning -- <command>
```

Examples

```
aws-vault exec terraform-learning -- terraform plan 
aws-vault exec terraform-learning -- terraform apply
```

# Northwind Infrastructure (Terraform)

This repository contains Infrastructure as Code (IaC) using Terraform to provision AWS infrastructure in a modular structure.

---

## Project Structure

```
env/
└── dev/
    ├── main.tf
    ├── variables.tf

modules/
├── network/
├── compute/
└── rds/

provider.tf
versions.tf
.gitignore
.github/workflows/
```

---

## What This Deploys

- VPC networking (public and private subnets)
- Application Load Balancer (ALB)
- EC2 compute instances
- Security groups
- RDS database instance

---

## Requirements

- Terraform >= 1.5
- AWS CLI installed and configured
- Valid AWS credentials with permissions

---

## AWS Authentication

```
aws configure
```

Or environment variables:

```
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_REGION="your_region"
```

---

## Terraform Commands

### Initialize

```
cd env/dev
terraform init
```

### Validate

```
terraform validate
```

### Plan

```
terraform plan
```

### Apply

```
terraform apply
```

### Destroy

```
terraform destroy
```

---

## Important Notes

Do NOT commit:

```
.terraform/
*.tfstate
*.tfstate.backup
crash.log
```

These are auto-generated and environment-specific.

---

## Best Practices

- Use remote state (S3 + DynamoDB recommended)
- Never store secrets in code
- Separate environments (dev/staging/prod)
- Use least-privilege IAM roles

---

## .gitignore

```
.terraform/
*.tfstate
*.tfstate.backup
crash.log
```

---

## Status

Dev environment is functional and modular.
Production requires remote state backend setup.
```

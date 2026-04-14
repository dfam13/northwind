# Northwind Infrastructure (Terraform)

This repository implements a modular Infrastructure as Code (IaC) solution using Terraform to provision a secure, scalable 2-tier AWS architecture.

The system includes a VPC networking layer, a PostgreSQL database in private subnets, and an auto-scaled application layer behind an Application Load Balancer.

It also includes a CI/CD pipeline design for intelligent, change-driven Terraform execution.

---

# Part 1: Foundation (Networking + Database)

## VPC

- CIDR: `192.168.0.0/16`
- Custom VPC created for full network isolation

## Subnets

- 2 Public Subnets (across 2 Availability Zones)
- 2 Private Subnets (across 2 Availability Zones)

Public subnets are used for internet-facing resources.
Private subnets are used for database and internal workloads.

## Routing

- Internet Gateway attached to VPC
- Public Route Table allows outbound internet access
- Private subnets have no direct internet access

---

## RDS (PostgreSQL)

- Engine: PostgreSQL
- Instance type: `db.t3.micro`
- Deployed inside private subnets

### Security Rules

- Database is NOT publicly accessible
- Only allows inbound traffic from VPC CIDR: `192.168.0.0/16`
- Security group restricts external access completely

---

# Part 2: Application Layer (Compute)

## Load Balancer (ALB)

- Type: Application Load Balancer
- Protocol: HTTP (port 80)
- Deployed in public subnets
- Uses official Terraform AWS modules

## Compute Layer

### Launch Template

- Amazon Linux 2023
- Instance type: `t3.micro`
- User Data installs Nginx automatically

```bash
#!/bin/bash
yum update -y
yum install nginx -y
systemctl enable nginx
systemctl start nginx
echo "Northwind App Running" > /usr/share/nginx/html/index.html
```

## Auto Scaling Group

- Min size: 1
- Max size: 3
- Integrated with ALB Target Group
- Instances distributed across Availability Zones

## Health Check

- Path: `/`
- Expected HTTP code: `200`

---

# Part 3: Smart CI/CD Pipeline

## Goal

Create a smart GitHub Actions pipeline that only runs Terraform where changes occur, preventing unnecessary executions and state conflicts.

---

## Pipeline Logic

### Rules

1. If changes occur in:
```
apps/payment-api/**
```
→ Run Terraform plan ONLY for Payment API

---

2. If changes occur in:
```
apps/user-api/**
```
→ Run Terraform plan ONLY for User API

---

3. If changes occur in:
```
global/iam/**
```
→ Run Terraform plan for ALL apps:
- payment-api
- user-api

Reason: IAM changes may impact all services

---

4. If changes occur only in:
```
CHANGELOG.md
```
→ Exit pipeline successfully (no Terraform execution)

---

## GitHub Actions Workflow

```yaml
name: Smart Terraform Pipeline

on:
  push:
    paths:
      - "apps/**"
      - "global/**"
      - "CHANGELOG.md"

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      payment: ${{ steps.filter.outputs.payment }}
      user: ${{ steps.filter.outputs.user }}
      iam: ${{ steps.filter.outputs.iam }}
      changelog_only: ${{ steps.filter.outputs.changelog_only }}

    steps:
      - uses: actions/checkout@v4

      - name: Detect Changed Paths
        id: filter
        run: |
          echo "payment=$(git diff --name-only ${{ github.event.before }} ${{ github.sha }} | grep '^apps/payment-api' && echo true || echo false)" >> $GITHUB_OUTPUT
          echo "user=$(git diff --name-only ${{ github.event.before }} ${{ github.sha }} | grep '^apps/user-api' && echo true || echo false)" >> $GITHUB_OUTPUT
          echo "iam=$(git diff --name-only ${{ github.event.before }} ${{ github.sha }} | grep '^global/iam' && echo true || echo false)" >> $GITHUB_OUTPUT
          echo "changelog_only=$(git diff --name-only ${{ github.event.before }} ${{ github.sha }} | grep -v 'CHANGELOG.md' || echo true)" >> $GITHUB_OUTPUT

  payment-plan:
    needs: detect-changes
    if: needs.detect-changes.outputs.payment == 'true' || needs.detect-changes.outputs.iam == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Running Payment API Terraform Plan"
      - run: terraform plan -chdir=apps/payment-api

  user-plan:
    needs: detect-changes
    if: needs.detect-changes.outputs.user == 'true' || needs.detect-changes.outputs.iam == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Running User API Terraform Plan"
      - run: terraform plan -chdir=apps/user-api

  skip-changelog:
    needs: detect-changes
    if: needs.detect-changes.outputs.payment == 'false' && needs.detect-changes.outputs.user == 'false' && needs.detect-changes.outputs.iam == 'false'
    runs-on: ubuntu-latest
    steps:
      - run: echo "No infrastructure changes detected. Skipping Terraform."
```

---

# Summary

This project demonstrates:

- Modular Terraform architecture
- Secure AWS infrastructure design
- Private database isolation
- Auto-scaled compute layer behind ALB
- DRY principles using reusable modules
- Smart CI/CD pipeline with change-based execution logic
```

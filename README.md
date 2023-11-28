# aws_terraform_deployment

This is the template that will deploy Ansible on AWS. While this template will work with any Ansible deployment on AWS, this is intended to be a starting point for customers that purchase Ansible Automation Platform subscriptions from the AWS marketplace. Take this template and enhance/improve/update based on the resources that you need for your AAP deployment.


## Getting Started

These sections will describe required or recommended steps so that your Ansible Automation Platform deployment is as seamless as possible.


### Red Hat Enterprise Linux

You will need to use a Red Hat Enterprise Linux (RHEL) Amazon Machine Image (AMI) as the foundation for your deployment.  While this collection will automatically find a public RHEL AMI available from AWS, public images bill for RHEL outside of your subscription for Ansible Automation Platform.

It is recommended that you create a custom AMI that you may then use to deploy RHEL with your subscriptions that come with Ansible Automation Platform.  [Red Hat Image Builder][image-builder] is a utility that makes creating a custom AMI easy.

## Deploying Ansible Automation Platform

This section will walk through deploying the AWS infrastructure and Ansible Automation Platform.

### Deploying Infrastructure

Initialize Terraform

```bash
terraform init
```

Check the plan

```bash
terraform plan
```

Apply infrastructure

```bash
terraform apply
```

Confirm to create infrastructure.
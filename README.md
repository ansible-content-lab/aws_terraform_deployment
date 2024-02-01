# aws_terraform_deployment

This is the template that will deploy Ansible on AWS. While this template will work with any Ansible deployment on AWS, this is intended to be a starting point for customers that purchase Ansible Automation Platform subscriptions from the AWS marketplace. Take this template and enhance/improve/update based on the resources that you need for your AAP deployment.

## Introduction

This template performs the following actions in the order listed.

| Step | Description |
| ---- | ----------- |
| Create a Deployment ID | Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP. |
| Create VPC | Creates a VPC with a CIDR block that can contain the number of subnets that will be created. |
| Create Subnets | Creates subnets for Controller, execution environments, Private Automation Hub, and Event-Driven Ansible. |
| Create IGW | Creates an internet gateway so that VMs have access to the internet. |
| Create Security Group | Creates a security group that allows AAP ports within the VPC, and HTTPS and automation mesh ports externally. |
| Create a Route Table | Creates a route table to route traffic properly. |
| Create Database | Creates an Amazon RDS instance for Controller, Private Automation Hub, and Event-Driven Ansible. |
| Create Controller VMs | Creates the virtual machines for each AAP component. |
| Create Hub VMs | Creates VMs for Private Automation Hub. |
| Create EDA VMs | Creates VMs for Event Driven Ansible. |
| Register VMs with Red Hat | Uses RHEL subscription manager to register each virtual machine for required RPM repos. |
| Update VMs | Updates each VM deployed with latest kernel and packages. |
| Configure SSH on installer VM | Configures the installer VMs with a private SSH key so that it can communicate with the other VMs that are part of the installation process. |
| Configure RDS Databases | Ensure that the RDS instance has a database for Controller, Hub, and Event-Driven Ansible. |
| Setup One Controller VM as Installer | Moves the locally downloaded AAP installer to a single VMs and configures the installer inventory file based on the VMs that were created as part of this process. |                 

## Getting Started

This section will walk through deploying the AWS infrastructure and Ansible Automation Platform.

You may also download the this repository from GitHub and modify to suit your needs.

### Red Hat Enterprise Linux

You will need to use a Red Hat Enterprise Linux (RHEL) Amazon Machine Image (AMI) as the foundation for your deployment.  While this collection will automatically find a public RHEL AMI available from AWS, public images bill for RHEL outside of your subscription for Ansible Automation Platform.

It is recommended that you create a custom AMI that you may then use to deploy RHEL with your subscriptions that come with Ansible Automation Platform.  [Red Hat Image Builder][image-builder] is a utility that makes creating a custom AMI easy.

### AWS Credentials

This terraform template requires AWS credentials for deploying infrastructure, which can be set by running command,
`aws configure`

This template will need a way to connect to the virtual machines that it creates.
By default, VMs are created with public IP addresses to make this simple, but the template may be modified to use private IP addresses if your local machine can route traffic to private networks.

## Deploying Ansible Automation Platform

This section will walk through deploying the AWS infrastructure and Ansible Automation Platform.

**NOTE:** This template is designed to provide a quick and easy setup with default values for the number of instances and instance types. However, these values can be customized to meet your specific requirements. 

### Checklist

- [ ] Install this repository
- [ ] Terraform installed locally (`terraform`)
- [ ] A RHEL AMI (if not using hourly RHEL instances)
- [ ] A locally downloaded copy of the [AAP installer][aap-installer]
- [ ] A variables file configured with required variables
- [ ] Configure the AWS environment variables for authentication
- [ ] An inventory file with the proper SSH configuration

### Deploying Infrastructure

The variables below are required for running this template

| Variable | Description |
| -------- | ----------- |
| `aap_red_hat_username` | This is your Red Hat account name that will be used for Subscription Management (https://access.redhat.com/management). |
| `aap_red_hat_password` | The Red Hat account password. |
| `infrastructure_db_username` | Username that will be the admin of the new database server. |
| `infrastructure_db_password` | Password of the admin of the new database server. |
| `aap_admin_password` | The admin password to create for Ansible Automation Platform application. |

The variables below are optional for running this template

| Variable | Description |
| -------- | ----------- |
| `deployment_id` | This is a random string that will be used in tagging for correlating the resources used with a deployment of AAP. It is lower case alpha chars between 2-10 char length. If not provided, template will generate the deployment_id. |
| `infrastructure_controller_count` | The number of instances for controller. |
| `infrastructure_controller_instance_type` | The SKU which should be used for controller Virtual Machine. |
| `infrastructure_eda_count` | The number of instances for Event-Driven Ansible. |
| `infrastructure_eda_instance_type` | The SKU which should be used for Event-Driven Ansible Virtual Machine. |
| `infrastructure_execution_count` | The number of instances for execution. |
| `infrastructure_execution_instance_type` | The SKU which should be used for execution Virtual Machine. |
| `infrastructure_hub_count` | The number of instances for hub. |
| `infrastructure_hub_instance_type` | The SKU which should be used for hub Virtual Machine. |
| `infrastructure_ssh_public_key` | SSH public key path. |
| `infrastructure_ssh_private_key` | SSH private key path. |
| `infrastructure_controller_ami` | The AMI for controller. In this template currently this value set to "" as default in which case it will pick RHEL AMI automatically. |
| `infrastructure_hub_ami` | The AMI for hub. In this template currently this value set to "" as default in which case it will pick RHEL AMI automatically. |
| `infrastructure_execution_ami` | The AMI for execution. In this template currently this value set to "" as default in which case it will pick RHEL AMI automatically. |
| `infrastructure_eda_ami` | The AMI for Even-Driven Ansible. In this template currently this value set to "" as default in which case it will pick RHEL AMI automatically. |

Additional variables can be found in variables.tf, modules/db/variables.tf , modules/vm/variables.tf, modules/vnet/variables.tf

Assuming that all variables are configured properly and your AWS account has permissions to deploy the resources defined in this template.

Initialize Terraform

```bash
terraform init -upgrade
```

Validate configuration
```bash
terraform validate
```

Check the plan

```bash
terraform plan -out=test-plan.tfplan
```

Apply infrastructure

```bash
terraform apply -var infrastructure_db_password=<db-password> -var aap_admin_password=<aap-admin-password> -var aap_red_hat_username=<redhat-username> -var aap_red_hat_password=<redhat-password>
```
Confirm to create infrastructure or pass in the `-auto-approve` parameter.

### Installing Red Hat Ansible Automation Platform

At this point you can ssh into one of the controller nodes and run the installer. The example below assumes the default variables.tf values for `infrastructure_admin_username` and `infrastructure_ssh_private_key`. 

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<controller-public-ip> 
```

Before you start the installation, you need to attach Ansible Automation Platform to the system where you're running the installer. 

Find the pool id for Ansible Automation Platform subscription using command 
```bash
sudo subscription-manager list --all --available
```

Attach subscription to all the VMs 
```bash
sudo subscription-manager attach --pool=<pool-id>
```

You need to transfer local installer from your local terminal to the installer host. Execute the following command on your local terminal to copy the installer RPM, which is available for download at this location [AAP installer][aap-installer]. Download x86_64 RPM package for `ansible-automation-platform-installer`. 
```bash
scp -i ~/.ssh/id_rsa <installer-rpm-filepath> ec2-user@<controller-public-ip>:~/.
```

Once you transfer installer RPM, install the installer by ssh into installer host
```bash
sudo rpm -ivh <installer-rpm-filepath>
```
At this point, the installer is installed on the path `/opt/ansible-automation-platform/installer`

We provided a sample inventory that could be used to deploy AAP.
You might need to edit the inventory to fit your needs.

You can copy inventory to `/opt/ansible-automation-platform/installer` for easy AAP installation.
```bash
sudo cp inventory_aws /opt/ansible-automation-platform/installer/inventory_aws
```

Run the installer to deploy Ansible Automation Platform
```bash
$ cd /opt/ansible-automation-platform/installer/
$ sudo ./setup.sh -i inventory_aws
```

For more information, read the install guide from https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/

## Uninstall

This will permanently remove all data and infrastructure from AWS environment, so only run this if you are sure that you want to delete all traces of the deployment.

```bash
terraform destroy
```
Confirm to destroy infrastructure or pass in the `-auto-approve` parameter.

**NOTE:**  If you do not unregister each VM from subscription manager before uninstall, for example, by using the following command on all the VMs:
```bash
sudo subscription-manager unregister
```
you can visit https://access.redhat.com/management/systems to remove the systems from subscription manager.

## Linting Terraform

We recommend using [tflint](https://github.com/terraform-linters/tflint) to help with maintaining  terraform syntax and standards.

### Initialize
```bash
tflint --init
```
### Running tflint
```bash
tflint --recursive
```

[image-builder]: https://console.redhat.com/insights/image-builder
[aap-installer]: https://access.redhat.com/downloads/content/480/ver=2.4/rhel---9/2.4/x86_64/packages
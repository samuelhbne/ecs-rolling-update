# ecs-rolling-update

This project is designed to deploy applications (Nginx by default) in the Amazon ECS cluster with a rolling update strategy. Thus, new application releases can be deployed to the ECS cluster without service interruption. Newly released application stack can be tested thoroughly via a different domain name before being promoted as primary service stack.

As a example application, the system was designed with moderate cost association: t2.small instance type by default, two Availability Zones (AZ's), default of only two container instances running. Optionally, you could increase the minimum number of application instances to 4 and will see an increase in availability and cost.

The Nginx container application will be inside an ECS cluster with managed Auto Scaling hence instance replacement will happen if there's a failure. The ECS cluster will be put into 2 private subnets spreaded in 2 Availability Zones with only port 80 reachable from LoadBalancer to ensure the application accessablity and security. A new TLS certificate for app.your-domain.com will be deployed to secure the secure the transfering between customer and LoadBalancer.

Optionally, CloudFront and Web Application Firewall (WAF) can be applied to accelerate the customer access in specific geo-area and protect the application from attacks like DDoS.

## Pre-requisites

An AWS account with resource creation permissions (EC2, ECS, ACM, S3, CloudWatch, Route53) will be necessary for the application deployment.

A pre-existing ssh key will be necessary for ECS instance access

A pre-existing Route53 zone will be necessary for the application deployment. A CNAME record for application sub-domain (app.your-domain.com by default) will be added into the existing Route53 hosted zone as well as the TLS certificate validation records.

A pre-existing S3 bucket will be necessary for Terraform state synchronisation. Please update the bucket name to match the S3 bucket name in main.cf accordingly.

```shell
terraform {
  backend "s3" {
    bucket          = "tfstate-samuelhbne"
    key             = "ecs-rolling-update/terraform.tfstate"
    region          = "us-east-1"
  }
}
```

The following Action secret items need to be set for the stack deployment.

```shell
AWS_ACCESS_KEY_ID       = "XXXXXXXXXXXXXXXXXXXX"
AWS_SECRET_ACCESS_KEY   = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
ENV                     = "yourdomain-com-prd"
DOMAIN                  = "yourdomain.com"
PUBLIC_KEY              = "ssh-rsa xxxxxx..."
```

## Pipelines

The Github Action workflows of this project will check potential risks and vulnerabilities in Terraform IaC code and application docker images.

In real world projects, more sophisticated tests like unit-tests, code rule checks, performance tests shall be introduced into the pipelines although did not implemented from upstream (Nginx).

### Terraform-Security

tfsec.yml workflow scans the Terraform code to find potential security IaC code issues and gives suggestions after. Scanning results will be sent to the Github security tab so they can be checked by the DevOps team late. This workflow will be triggered on master pull-requests as well as master/dev pushes.

### Terraform-Checks

tfcheck.yml workflow validates the Terraform IaC code, then runs terraform to plan the changes that will be applied on the stack. After these, Trivy scanner will scan the application image to check possible vulnerabilities and put the result into the Github security tab. This workflow will be triggered on master pull-requests as well as master/dev pushes.

### Terraform-Deployment

tfdeploy.yml workflow validates the Terraform IaC code before updating stacks on the ECS cluster. This workflow will be triggered on master pushes only.

## To add a new application stack

To add a new application stack, a new mapp item needs to be added into the "STACKS" variable in variables.tf to indicate the new DNS subdomain name as well as the application image of this new stack.

Like the following:

```shell
variable "STACKS" {
  description   = "Product stacks to deploy. Format: domain-name = release-version"
  default       = {
    "app122"    = "nginx:1.22"
    "app123"    = "nginx:1.23"
  }
}
```

## To switch the current service application stack

To switch the service application stack to a different version, the variable "SERVICE_STACK" in variables.tf needs to be updated to point to specific stack like the following:

```shell
variable "SERVICE_STACK" {
  description   = "Product stack on service"
  default       = "app123"
}
```

## TODO

Although not listed as requirements, I would do the following if I have more time:

- Tweaking ECS/ASG scripts for "awsvpc" ENI trunking to optimise the ECS cluster in microservice environment.

- Add Trivy scanning for all application images besides the current service stack image.

- Add alert notification after pipeline scanning

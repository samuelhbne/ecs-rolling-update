# ecs-rolling-update

This project is designed to deploy applications (Nginx by default) in the Amazon ECS cluster with a rolling update strategy. Thus, new application releases can be deployed to the ECS cluster without service interruption. Newly released application stack can be tested thoroughly via a different domain name before being promoted as primary service stack.

## Pipelines

The Github Action workflows of this project will check potential risks and vulnerabilities in Terraform IaC code and application docker images.

In real world projects, more sophisticated tests like unit-tests, code rule check, performance tests shall be introduced into the pipelines although did not implemented here.

### CI pipelines

tfsec.yml workflow scans the Terraform code to find potential security IaC code issues and gives suggestions after. Scanning results will be sent to the Github security tab so they can be checked by the DevOps team late. This workflow will be triggered on master pull-requests as well as master/dev pushes.

tfcheck.yml workflow validates the Terraform IaC code, then runs terraform to plan the changes that will be applied on the stack. After these, Trivy scanner will scan the application image to check possible vulnerabilities and put the result into the Github security tab. This workflow will be triggered on master pull-requests as well as master/dev pushes.

deployment.yml workflow validates the Terraform IaC code before updating stacks on the ECS cluster. This workflow will be triggered on master pushes only.

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

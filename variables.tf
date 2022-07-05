variable "BACKEND_BUCKET" {
  description   = "S3 bucket name for terraform backend"
  default       = "tfstate-samuelhbne"
}

variable "BACKEND_KEY" {
  description   = "tfstate key file path"
  default       = "ecs-rolling-update/terraform.tfstate"
}

variable "AWS_REGION" {
  description   = "AWS region to create resources"
  default       = "us-east-1"
}

variable "AZ" {
  description   = "AWS availablity zone to create resources"
  default       = ["us-east-1a", "us-east-1b"]
}

variable "PUBLIC_CIDR" {
  description   = "Public subnet CIDR"
  default       = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "PRIVATE_CIDR" {
  description   = "Private subnet CIDR"
  default       = ["10.0.128.0/24", "10.0.129.0/24"]
}

variable "AWS_INSTANCE_TYPE" {
  description   = "ECS cluster instance type"
  default       = "t2.small"
}

variable "AWS_INSTANCE_ARCH" {
  description   = "AWS instance architecture"
  default       = "x86_64"
}




variable "DOMAIN" {
  description   = "Domain name to be deployed"
  default       = "your-domain.com"
}

variable "ENV" {
  description   = "Prefix of all AWS resource names the stack created"
  default       = "your-domain-com"
}

variable "AWS_ACCESS_KEY_ID" {
  description   = "AWS access key ID"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description   = "AWS access secret"
}

variable "PUBLIC_KEY" {
  description   = "SSH public key to login into instance"
  type          = string
}




variable "STACKS" {
  description   = "Product stacks to deploy. Format: domain-name = release-version"
  default       = {
    "app122"    = "1.22"
    "app123"    = "1.23"
  }
}

variable "SERVICE_STACK" {
  description   = "Product stack on service"
  default       = "app123"
}

variable "SERVICE_DOMAIN" {
  description   = "Primary sub-domain name for prd service"
  default       = "www"
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
  }
}

variable "domain_names" {
  description = "Domain names served by the site."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN issued in us-east-1."
  type        = string
}

module "this" {
  source = "../../"

  name = "olensys-test-site"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "site"
    owner        = "platform"
    cost_center  = "eng"
  }

  domain_names    = var.domain_names
  certificate_arn = var.certificate_arn
}

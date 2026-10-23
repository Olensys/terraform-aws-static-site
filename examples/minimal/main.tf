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

  name = "example"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  domain_names    = var.domain_names
  certificate_arn = var.certificate_arn
}

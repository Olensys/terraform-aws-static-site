terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws        = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
    cloudflare = { source = "cloudflare/cloudflare", version = ">= 5.0, < 6.0" }
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID of the test zone the certificate validation record is created in."
  type        = string
}

variable "zone_domain" {
  description = "Domain of the Cloudflare test zone; the site is served at site.<zone_domain>."
  type        = string
  default     = "tf-test.olensys.com"
}

# Default provider: region from the environment. The aliased provider is for the certificate only.
provider "aws" {}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Reads CLOUDFLARE_API_TOKEN from the environment.
provider "cloudflare" {}

resource "aws_acm_certificate" "site" {
  provider = aws.us_east_1

  domain_name       = "site.${var.zone_domain}"
  validation_method = "DNS"
  key_algorithm     = "EC_prime256v1"

  lifecycle {
    create_before_destroy = true
  }
}

# One domain, no SANs: exactly one validation option.
locals { validation = one(aws_acm_certificate.site.domain_validation_options) }

resource "cloudflare_dns_record" "validation" {
  zone_id = var.zone_id
  name    = trimsuffix(local.validation.resource_record_name, ".")
  type    = local.validation.resource_record_type
  content = trimsuffix(local.validation.resource_record_value, ".")
  ttl     = 60
}

resource "aws_acm_certificate_validation" "site" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [cloudflare_dns_record.validation.name]
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

  domain_names    = ["site.${var.zone_domain}"]
  certificate_arn = aws_acm_certificate_validation.site.certificate_arn
}

output "domain_name" {
  description = "CloudFront distribution domain name."
  value       = module.this.domain_name
}

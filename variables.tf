variable "name" {
  description = "Resource name. Lowercase letters, digits and hyphens."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.name))
    error_message = "name must match ^[a-z0-9-]{1,63}$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}

variable "domain_names" {
  description = "Alternate domain names (CNAMEs) served by the distribution. Must be covered by the certificate."
  type        = list(string)
  validation {
    condition     = length(var.domain_names) > 0
    error_message = "domain_names must contain at least one domain."
  }
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for domain_names. Must be issued in us-east-1."
  type        = string
}

variable "default_root_object" {
  description = "Object CloudFront returns for requests to the root URL."
  type        = string
  default     = "index.html"
}

variable "spa_fallback" {
  description = "Map 403 and 404 responses to /index.html with status 200 so client-side routing works."
  type        = bool
  default     = true
}

variable "cache_policy" {
  description = "TTLs in seconds for the cache policy. No cookies, headers or query strings are forwarded."
  type = object({
    default_ttl = optional(number, 86400)
    max_ttl     = optional(number, 31536000)
    min_ttl     = optional(number, 0)
  })
  default = {}
}

variable "functions" {
  description = "CloudFront functions (cloudfront-js-2.0) keyed by short name; at most one per event_type (viewer-request or viewer-response)."
  type = map(object({
    event_type = string
    code       = string
  }))
  default = {}
  validation {
    condition     = alltrue([for f in var.functions : contains(["viewer-request", "viewer-response"], f.event_type)])
    error_message = "functions event_type must be viewer-request or viewer-response."
  }
  validation {
    condition     = length(distinct([for f in var.functions : f.event_type])) == length(var.functions)
    error_message = "At most one function per event_type."
  }
}

variable "web_acl_arn" {
  description = "ARN of a WAFv2 web ACL (scope CLOUDFRONT) to attach, or null for none."
  type        = string
  default     = null
}

variable "response_headers_policy_id" {
  description = "ID of a CloudFront response headers policy (for example CORS) to attach to the default cache behaviour, or null for none."
  type        = string
  default     = null
}

variable "logging_bucket" {
  description = "S3 bucket domain name (for example logs.s3.amazonaws.com) for standard access logs, or null to disable logging."
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class: PriceClass_100, PriceClass_200 or PriceClass_All."
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200 or PriceClass_All."
  }
}

variable "tags" {
  description = "Tags merged onto every taggable resource, applied last."
  type        = map(string)
  default     = {}
}

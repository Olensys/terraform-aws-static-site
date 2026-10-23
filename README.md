# terraform-aws-static-site

Static website on CloudFront with a private S3 origin behind Origin Access Control, HTTPS-only, SPA fallback

## Opinions

- Origin access control (SigV4, always signing) on the S3 origin; never origin access identity.
- The origin bucket is private: all public access blocked, TLS-only, BucketOwnerEnforced, SSE-S3. Its policy allows only `s3:GetObject` to `cloudfront.amazonaws.com` with `AWS:SourceArn` set to this distribution.
- `viewer_protocol_policy = "redirect-to-https"`; certificate served over SNI with minimum protocol `TLSv1.2_2021`.
- `http_version = "http2and3"`, IPv6 enabled, compression on, methods GET/HEAD/OPTIONS (cached GET/HEAD), `wait_for_deployment = false`.
- `spa_fallback` (default true) maps 403 and 404 to `/index.html` with status 200 and a 10 second error cache.
- A cache policy with the `cache_policy` TTLs (default 86400/31536000/0), gzip and brotli, and no cookies, headers or query strings in the cache key.
- `functions` become published `cloudfront-js-2.0` functions, attached at most one per `viewer-request` or `viewer-response`.
- `price_class` defaults to `PriceClass_100`; `web_acl_arn` and `logging_bucket` (bucket domain name) are optional.
- The certificate must be in `us-east-1`: pass the `terraform-aws-acm-certificate` output, created with an aliased `us-east-1` provider.
- The origin access control and the cache policy are both named `name`; CloudFront names these account-global, so `name` must be unique per account.
- DNS is the consumer's job: point a CNAME for each of `domain_names` at the `domain_name` output with `terraform-cloudflare-dns` or Route53.

## Usage

```hcl
module "this" {
  source = "git::https://github.com/Olensys/terraform-aws-static-site.git?ref=v1.0.0"

  name = "example"
  context = {
    organization = "olensys"
    environment  = "dev"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  domain_names    = ["www.example.com"]
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0, < 7.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_bucket"></a> [bucket](#module\_bucket) | terraform-aws-modules/s3-bucket/aws | 5.17.0 |
| <a name="module_this"></a> [this](#module\_this) | terraform-aws-modules/cloudfront/aws | 6.7.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudfront_cache_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of the ACM certificate for domain\_names. Must be issued in us-east-1. | `string` | n/a | yes |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_domain_names"></a> [domain\_names](#input\_domain\_names) | Alternate domain names (CNAMEs) served by the distribution. Must be covered by the certificate. | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Resource name. Lowercase letters, digits and hyphens. | `string` | n/a | yes |
| <a name="input_cache_policy"></a> [cache\_policy](#input\_cache\_policy) | TTLs in seconds for the cache policy. No cookies, headers or query strings are forwarded. | <pre>object({<br/>    default_ttl = optional(number, 86400)<br/>    max_ttl     = optional(number, 31536000)<br/>    min_ttl     = optional(number, 0)<br/>  })</pre> | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Object CloudFront returns for requests to the root URL. | `string` | `"index.html"` | no |
| <a name="input_functions"></a> [functions](#input\_functions) | CloudFront functions (cloudfront-js-2.0) keyed by short name; at most one per event\_type (viewer-request or viewer-response). | <pre>map(object({<br/>    event_type = string<br/>    code       = string<br/>  }))</pre> | `{}` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | S3 bucket domain name (for example logs.s3.amazonaws.com) for standard access logs, or null to disable logging. | `string` | `null` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | CloudFront price class: PriceClass\_100, PriceClass\_200 or PriceClass\_All. | `string` | `"PriceClass_100"` | no |
| <a name="input_spa_fallback"></a> [spa\_fallback](#input\_spa\_fallback) | Map 403 and 404 responses to /index.html with status 200 so client-side routing works. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto every taggable resource, applied last. | `map(string)` | `{}` | no |
| <a name="input_web_acl_arn"></a> [web\_acl\_arn](#input\_web\_acl\_arn) | ARN of a WAFv2 web ACL (scope CLOUDFRONT) to attach, or null for none. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the CloudFront distribution. Null when create is false. |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the private origin bucket. Null when create is false. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the private origin bucket. Null when create is false. |
| <a name="output_bucket_policy_json"></a> [bucket\_policy\_json](#output\_bucket\_policy\_json) | Bucket policy document granting the distribution read access. Null when create is false. |
| <a name="output_custom_error_responses"></a> [custom\_error\_responses](#output\_custom\_error\_responses) | Custom error responses passed to the distribution. Null when create is false. |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | CloudFront domain name; point domain\_names CNAME records here. Null when create is false. |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | Route 53 hosted zone ID of CloudFront, for alias records. Null when create is false. |
| <a name="output_id"></a> [id](#output\_id) | ID of the CloudFront distribution. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Name of the site (also the bucket name). Null when create is false. |
| <a name="output_origin_access_control_enabled"></a> [origin\_access\_control\_enabled](#output\_origin\_access\_control\_enabled) | Whether the origin is protected by origin access control: true when created, false when create is false (no access control is created then). |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to every taggable resource, with context.extra\_tags merged in. Null when create is false. |
| <a name="output_viewer_protocol_policy"></a> [viewer\_protocol\_policy](#output\_viewer\_protocol\_policy) | Viewer protocol policy of the default cache behavior. Null when create is false. |
<!-- END_TF_DOCS -->

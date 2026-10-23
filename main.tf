# Two upstream calls: `bucket` (private S3 origin) and `this` (CloudFront distribution).

locals {
  # Merge onto every taggable resource, with var.tags applied last.
  tags = merge(var.context.extra_tags, var.tags)

  origin_id = "s3"

  # Upstream creates these regardless of its own create flag, so gate here.
  origin_access_control = var.create ? {
    s3 = {
      description      = "Origin access control for ${var.name}"
      name             = var.name
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  } : {}

  viewer_protocol_policy = "redirect-to-https"

  custom_error_responses = var.spa_fallback ? [
    for code in [403, 404] : {
      error_code            = code
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 10
    }
  ] : []

  # Only the distribution may read objects, and only GetObject.
  bucket_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipalReadOnly"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "arn:${data.aws_partition.current.partition}:s3:::${var.name}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = module.this.cloudfront_distribution_arn }
      }
    }]
  })
}

data "aws_partition" "current" {}

resource "aws_cloudfront_cache_policy" "this" {
  count = var.create ? 1 : 0

  name        = var.name
  comment     = "Cache policy for ${var.name}"
  default_ttl = var.cache_policy.default_ttl
  max_ttl     = var.cache_policy.max_ttl
  min_ttl     = var.cache_policy.min_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_function" "this" {
  for_each = var.create ? var.functions : {}

  name    = "${var.name}-${each.key}"
  runtime = "cloudfront-js-2.0"
  comment = "${var.name} ${each.key}"
  publish = true
  code    = each.value.code
}

module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.17.0"

  create_bucket = var.create
  bucket        = var.name

  # Opinions: never public, owner-enforced, TLS only, SSE-S3.
  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true
  control_object_ownership              = true
  object_ownership                      = "BucketOwnerEnforced"
  attach_deny_insecure_transport_policy = true

  # Merged upstream with the deny-insecure-transport statement.
  attach_policy = true
  policy        = local.bucket_policy_json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

module "this" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.7.1"

  create              = var.create
  comment             = "Static site ${var.name}"
  enabled             = true
  aliases             = var.domain_names
  default_root_object = var.default_root_object
  price_class         = var.price_class
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  web_acl_id          = var.web_acl_arn
  wait_for_deployment = false

  origin_access_control = local.origin_access_control

  origin = {
    (local.origin_id) = {
      domain_name               = module.bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control_key = "s3"
    }
  }

  default_cache_behavior = {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = local.viewer_protocol_policy
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = var.create ? aws_cloudfront_cache_policy.this[0].id : null

    function_association = {
      for k, f in(var.create ? var.functions : {}) : f.event_type => {
        event_type   = f.event_type
        function_arn = aws_cloudfront_function.this[k].arn
      }
    }
  }

  custom_error_response = local.custom_error_responses

  viewer_certificate = {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  logging_config = var.logging_bucket == null ? null : {
    bucket          = var.logging_bucket
    include_cookies = false
    prefix          = var.name
  }

  tags = local.tags
}

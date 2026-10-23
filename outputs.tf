output "id" {
  description = "ID of the CloudFront distribution. Null when create is false."
  value       = var.create ? module.this.cloudfront_distribution_id : null
}

output "name" {
  description = "Name of the site (also the bucket name). Null when create is false."
  value       = var.create ? var.name : null
}

output "arn" {
  description = "ARN of the CloudFront distribution. Null when create is false."
  value       = var.create ? module.this.cloudfront_distribution_arn : null
}

output "domain_name" {
  description = "CloudFront domain name; point domain_names CNAME records here. Null when create is false."
  value       = var.create ? module.this.cloudfront_distribution_domain_name : null
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID of CloudFront, for alias records. Null when create is false."
  value       = var.create ? module.this.cloudfront_distribution_hosted_zone_id : null
}

output "bucket_name" {
  description = "Name of the private origin bucket. Null when create is false."
  value       = var.create ? module.bucket.s3_bucket_id : null
}

output "bucket_arn" {
  description = "ARN of the private origin bucket. Null when create is false."
  value       = var.create ? module.bucket.s3_bucket_arn : null
}

output "tags" {
  description = "Tags applied to every taggable resource, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.tags : null
}

output "origin_access_control_enabled" {
  description = "Whether the origin is protected by origin access control: true when created, false when create is false (no access control is created then)."
  value       = length(local.origin_access_control) > 0
}

output "viewer_protocol_policy" {
  description = "Viewer protocol policy of the default cache behavior. Null when create is false."
  value       = var.create ? local.viewer_protocol_policy : null
}

output "custom_error_responses" {
  description = "Custom error responses passed to the distribution. Null when create is false."
  value       = var.create ? local.custom_error_responses : null
}

output "bucket_policy_json" {
  description = "Bucket policy document granting the distribution read access. Null when create is false."
  value       = var.create ? local.bucket_policy_json : null
}

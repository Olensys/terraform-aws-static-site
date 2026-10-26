mock_provider "aws" {
  # Upstream feeds policy documents back through JSON parsing; mocks must return valid JSON.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"mock\",\"Effect\":\"Deny\",\"Action\":\"s3:*\",\"Resource\":\"*\"}]}"
    }
  }
}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name            = "example"
  domain_names    = ["www.example.com"]
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
}

# Replace the distribution module so its ARN is known at plan time; the
# bucket policy document built in the root can then be asserted for real.
override_module {
  target = module.this
  outputs = {
    cloudfront_distribution_id             = "EDFDVBD6EXAMPLE"
    cloudfront_distribution_arn            = "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
    cloudfront_distribution_domain_name    = "d111111abcdef8.cloudfront.net"
    cloudfront_distribution_hosted_zone_id = "Z2FDTNDATAQYW2"
  }
}

run "test_oac_used_and_no_oai" {
  # SMOKE: asserts the OAC map handed to the upstream module is non-empty (OAI is not wired anywhere); the real distribution attribute is proven by complete.tftest.hcl and trivy.
  command = plan

  assert {
    condition     = output.origin_access_control_enabled == true
    error_message = "Origin access control must be enabled."
  }
}

run "test_https_redirect" {
  # SMOKE: asserts the viewer_protocol_policy local passed to the upstream module; the applied behaviour is proven by complete.tftest.hcl.
  command = plan

  assert {
    condition     = output.viewer_protocol_policy == "redirect-to-https"
    error_message = "Viewers must be redirected to HTTPS."
  }
}

run "test_spa_fallback_error_responses" {
  # SMOKE: asserts the custom_error_response list passed to the upstream module; the applied distribution is proven by complete.tftest.hcl.
  command = plan

  assert {
    condition     = length(output.custom_error_responses) == 2
    error_message = "SPA fallback must configure two error responses."
  }

  assert {
    condition     = alltrue([for r in output.custom_error_responses : r.response_code == 200 && r.response_page_path == "/index.html"]) && toset([for r in output.custom_error_responses : r.error_code]) == toset([403, 404])
    error_message = "403 and 404 must map to /index.html with 200."
  }
}

run "test_spa_fallback_disabled" {
  command = plan

  variables {
    spa_fallback = false
  }

  assert {
    condition     = length(output.custom_error_responses) == 0
    error_message = "No error responses without spa_fallback."
  }
}

run "test_bucket_policy_scoped_to_distribution" {
  command = plan

  assert {
    condition     = strcontains(output.bucket_policy_json, "cloudfront.amazonaws.com") && strcontains(output.bucket_policy_json, "AWS:SourceArn")
    error_message = "Policy must allow the CloudFront service principal conditioned on AWS:SourceArn."
  }

  assert {
    condition     = strcontains(output.bucket_policy_json, "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE") && strcontains(output.bucket_policy_json, "s3:GetObject")
    error_message = "Policy must be scoped to the distribution ARN and grant only s3:GetObject."
  }
}

run "test_cache_policy_ttls" {
  command = plan

  assert {
    condition     = aws_cloudfront_cache_policy.this[0].default_ttl == 86400 && aws_cloudfront_cache_policy.this[0].max_ttl == 31536000 && aws_cloudfront_cache_policy.this[0].min_ttl == 0
    error_message = "Cache policy TTLs must default to 86400/31536000/0."
  }
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition = alltrue([
      output.id == null, output.name == null, output.arn == null, output.domain_name == null,
      output.hosted_zone_id == null, output.bucket_name == null, output.bucket_arn == null,
      output.tags == null, output.origin_access_control_enabled == false,
      output.viewer_protocol_policy == null, output.custom_error_responses == null,
      output.bucket_policy_json == null,
    ])
    error_message = "All outputs must be null when create is false."
  }

  assert {
    condition     = length(aws_cloudfront_cache_policy.this) == 0 && length(aws_cloudfront_function.this) == 0
    error_message = "No root resources when create is false."
  }
}

run "test_function_association" {
  # SMOKE: asserts the root function resource settings only; the association on the distribution is proven by complete.tftest.hcl.
  command = plan

  variables {
    functions = {
      rewrite = { event_type = "viewer-request", code = "function handler(event) { return event.request; }" }
    }
  }

  assert {
    condition     = aws_cloudfront_function.this["rewrite"].runtime == "cloudfront-js-2.0" && aws_cloudfront_function.this["rewrite"].publish == true
    error_message = "Functions must use cloudfront-js-2.0 and be published."
  }
}

run "test_response_headers_policy_accepted" {
  # SMOKE: the policy id goes to the upstream module's default behaviour and is not visible here; asserts the input plans.
  command = plan

  variables {
    response_headers_policy_id = "27d627a2-0f86-443d-a056-f328bf19733f"
  }

  assert {
    condition     = output.viewer_protocol_policy == "redirect-to-https"
    error_message = "A response headers policy id must plan cleanly."
  }
}

run "test_create_false_passes_no_oac" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = output.origin_access_control_enabled == false
    error_message = "No origin access control may be passed to the distribution when create is false."
  }
}

run "test_create_false_with_functions" {
  command = plan

  variables {
    create = false
    functions = {
      rewrite = { event_type = "viewer-request", code = "function handler(event) { return event.request; }" }
    }
  }

  assert {
    condition     = length(aws_cloudfront_function.this) == 0 && length(aws_cloudfront_cache_policy.this) == 0
    error_message = "No root resources when create is false, even with functions set."
  }
}

run "test_price_class_validation" {
  command = plan

  variables {
    price_class = "PriceClass_Bogus"
  }

  expect_failures = [var.price_class]
}

run "test_function_event_type_validation" {
  command = plan

  variables {
    functions = {
      bad = { event_type = "origin-request", code = "function handler(e) { return e.request; }" }
    }
  }

  expect_failures = [var.functions]
}

run "test_domain_names_validation" {
  command = plan

  variables {
    domain_names = []
  }

  expect_failures = [var.domain_names]
}

run "test_tags_contract" {
  command = plan

  variables {
    tags = { Owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { Owner = "y", Team = "z" }
    }
  }

  assert {
    condition     = output.tags.Owner == "x"
    error_message = "var.tags must win over context.extra_tags."
  }

  assert {
    condition     = output.tags.Team == "z"
    error_message = "context.extra_tags must be merged."
  }
}

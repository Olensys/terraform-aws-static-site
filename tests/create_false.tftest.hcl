# No override_module here: the real upstream modules are planned with create = false.
mock_provider "aws" {
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
  create          = false
  domain_names    = ["www.example.com"]
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
  functions = {
    rewrite = { event_type = "viewer-request", code = "function handler(event) { return event.request; }" }
  }
}

run "test_create_false_real_modules_plan_nothing" {
  command = plan

  assert {
    condition     = output.id == null && output.arn == null && output.bucket_arn == null && output.origin_access_control_enabled == false
    error_message = "Outputs must be null (OAC false) when create is false."
  }

  assert {
    condition     = length(aws_cloudfront_function.this) == 0 && length(aws_cloudfront_cache_policy.this) == 0
    error_message = "No root resources when create is false."
  }
}

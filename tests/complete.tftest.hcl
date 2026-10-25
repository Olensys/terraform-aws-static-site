# Run only by the nightly integration workflow, against real cloud credentials.
# The example provisions its own us-east-1 certificate, validated through Cloudflare.
# Inputs: TF_VAR_zone_id (and optionally TF_VAR_zone_domain); CLOUDFLARE_API_TOKEN in the environment.
run "apply_minimal" {
  command = apply

  module {
    source = "./examples/minimal"
  }

  assert {
    condition     = output.domain_name != null
    error_message = "the distribution must be created and expose its domain name."
  }
}

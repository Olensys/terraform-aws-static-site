# Run only by the nightly integration workflow, against real cloud credentials.
# The certificate must exist in us-east-1; supply its ARN and a matching domain.
run "apply_minimal" {
  command = apply

  module {
    source = "./examples/minimal"
  }
}

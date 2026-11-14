# Changelog

## [1.1.0](https://github.com/Olensys/terraform-aws-static-site/compare/v1.0.5...v1.1.0) (2026-11-14)


### Features

* serve on the default CloudFront certificate when no domain is set ([#9](https://github.com/Olensys/terraform-aws-static-site/issues/9)) ([8d196ce](https://github.com/Olensys/terraform-aws-static-site/commit/8d196ce8a6184374ed236d7606fb53fb4fbd0995))

## 1.1.0

### Behaviour changes

`domain_names` and `certificate_arn` are now optional (defaults `[]` and `null`). An empty `domain_names` no longer fails validation: it now yields a site served on the distribution's own `*.cloudfront.net` domain with the default CloudFront certificate, whose minimum TLS protocol CloudFront fixes at `TLSv1`. Setting `domain_names` without `certificate_arn` still fails, now through a precondition on the `id` output instead of a variable validation. Behaviour with a domain and a certificate is unchanged.

## [1.0.5](https://github.com/Olensys/terraform-aws-static-site/compare/v1.0.4...v1.0.5) (2026-11-14)


### Bug Fixes

* tag the examples' resources through the naming module ([#10](https://github.com/Olensys/terraform-aws-static-site/issues/10)) ([3c1fbdc](https://github.com/Olensys/terraform-aws-static-site/commit/3c1fbdcd6cd2c548a0a781b1fc2f0bc6b7c0b6a4))

## [1.0.4](https://github.com/Olensys/terraform-aws-static-site/compare/v1.0.3...v1.0.4) (2026-10-26)


### Bug Fixes

* **examples:** provision the certificate in us-east-1 and validate through Cloudflare ([#4](https://github.com/Olensys/terraform-aws-static-site/issues/4)) ([835ef9c](https://github.com/Olensys/terraform-aws-static-site/commit/835ef9cf281292e1564bed69ee7474764328e792))
* optional response_headers_policy_id on the default cache behaviour ([#7](https://github.com/Olensys/terraform-aws-static-site/issues/7)) ([f84e46c](https://github.com/Olensys/terraform-aws-static-site/commit/f84e46c276499b71334314dc4f1c4d41e5ce4588))

## [1.0.3](https://github.com/Olensys/terraform-aws-static-site/compare/v1.0.2...v1.0.3) (2026-10-24)


### Bug Fixes

* **examples:** unique application slug so concurrent integration runs do not collide ([#2](https://github.com/Olensys/terraform-aws-static-site/issues/2)) ([82b8b7a](https://github.com/Olensys/terraform-aws-static-site/commit/82b8b7a4f89bf0f5e5330bb0ae02f4fc0c81dca6))

## [1.0.2](https://github.com/Olensys/terraform-aws-static-site/compare/v1.0.1...v1.0.2) (2026-10-24)


### Bug Fixes

* run integration on change and weekly instead of nightly ([ba4f498](https://github.com/Olensys/terraform-aws-static-site/commit/ba4f498e4735f6547e8ab4476ec0b6a46cdf65f1))

## 1.0.1

### Fixes

- gate origin access control and function association on create
- declare required version and providers in the minimal example

### Other

- disable lockfile in docs and skip .terraform in trivy hook

## 1.0.0

- Static website on CloudFront with a private S3 origin behind Origin Access Control, HTTPS-only, with optional SPA fallback, cache policy, viewer functions, WAF and access logging.

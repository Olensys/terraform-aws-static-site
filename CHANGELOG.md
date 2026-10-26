# Changelog

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

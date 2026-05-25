### What's changed in v1.3.0

* feat: typed spec.extensionProviders[] for ext_authz registrations (#32) (by @patrickleet)

  Adds a typed surface on IstioStack for registering Istio MeshConfig
  ExtensionProviders (HTTP + gRPC). Per-namespace oauth2-proxy bridges
  declare themselves once; AuthorizationPolicy.CUSTOM rules in any
  consumer namespace reference the registered name. Render fails with
  actionable messages on missing name, duplicate name, both modes set,
  or neither mode set. Status surface exposes the configured provider
  list so consumers can gate AuthorizationPolicy MRs on readiness.

  End-to-end verified on pat-local: registered smoke-test-ext-authz
  points at a deny-403 nginx; waypoint Envoy access log shows
  "302 UAEX ext_authz_denied" via the registered provider.

  Implements [[tasks/istio-stack-extension-providers]]
  Pattern: [[specs/platform-public-exposure]]

* chore(deps): update unbounded-tech/workflow-vnext-tag action to v1.21.3 (#29) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>

* chore(deps): update unbounded-tech/workflow-simple-release action to v2.1.3 (#28) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>


See full diff: [v1.2.0...v1.3.0](https://github.com/hops-ops/istio-stack/compare/v1.2.0...v1.3.0)

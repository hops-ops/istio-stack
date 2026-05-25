### What's changed in v1.3.1

* fix: add istio resource defaults (#33) (by @patrickleet)

  Summary:
  - Add explicit resource requests/limits for istiod, istio-cni, and ztunnel chart defaults.
  - Preserve existing Helm values override behavior by merging user values over chart defaults.
  - Cover default resource requests in render tests.


See full diff: [v1.3.0...v1.3.1](https://github.com/hops-ops/istio-stack/compare/v1.3.0...v1.3.1)

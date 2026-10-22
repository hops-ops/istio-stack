### What's changed in v1.4.2

* chore(deps): update helm release base to v1.30.4 (#37) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>

* chore(deps): update unbounded-tech/workflow-vnext-tag action to v1.22.3 (#35) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>

* chore(deps): migrate workflows-crossplane to hops-ops@v3.2.0 (by @renovate[bot])

  * chore(deps): update unbounded-tech/workflows-crossplane action to v3

  * chore(deps): migrate workflows-crossplane to hops-ops@v3.2.0

  ---------

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>
  Co-authored-by: Patrick Lee Scott <pat@patscott.io>

* chore(deps): update helm release base to v1.30.5 (#38) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>

* chore(deps): update helm release base to v1.30.6 (#39) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>

* fix(deps): update helm release base to v1.30.7 (#40) (by @renovate[bot])

  XR-rendered default chartVersion (base/istiod/ztunnel) 1.30.6 -> 1.30.7, so fix(deps) to cut a release; also ships the earlier unreleased chore bumps (1.30.5/1.30.6).

  1.30.7 is a security patch (ISTIO-SECURITY-2026-008: eMudhra CA distrust, Go 1.26.10 CVE-2026-111943, ztunnel rustls-webpki 0.103.16) plus fixes: istiod restarts with expired self-signed CA, ambient untaint ztunnel check is opt-in (PILOT_NODE_UNTAINT_CHECK_ZTUNNEL, off by default). No values we set (profile ambient, pilot/ztunnel resources) changed.

  test, validate x3 and e2e green; e2e installs base/istiod/ztunnel to Ready on kind.


See full diff: [v1.4.1...v1.4.2](https://github.com/hops-ops/istio-stack/compare/v1.4.1...v1.4.2)

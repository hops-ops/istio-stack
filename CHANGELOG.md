### What's changed in v1.0.0

* feat: rebuild on Istio Ambient + Gateway API (by @patrickleet)

  BREAKING CHANGE: Replaces the sidecar-mode Istio install with ambient dataplane:
  - istio-base + istiod (profile: ambient)
  - istio-cni DaemonSet (manages traffic redirection)
  - ztunnel DaemonSet (per-node mTLS terminator)
  - Platform Gateway (Gateway API gateway.networking.k8s.io/v1)

  Removed (sidecar-era):
  - 100-namespace, 190-helm-release-base, 200-helm-release-istiod,
    210-helm-release-gateways, 215-egress-service-entries
  - 005-state-istio, 001-state-observed-helm
  - examples/ha.yaml, examples/local.yaml
  - PeerAuthentication composition (ambient handles mTLS at node level)
  - Sidecar injection labels (ambient uses namespace dataplane labels at consumer level)

  New render templates:
  - 100-control-plane-namespace.yaml.gotmpl
  - 200-istio-base.yaml.gotmpl
  - 210-istiod.yaml.gotmpl (profile: ambient)
  - 215-istio-cni.yaml.gotmpl
  - 220-ztunnel.yaml.gotmpl
  - 230-ingress-namespace.yaml.gotmpl
  - 240-gateway.yaml.gotmpl (Gateway API resource)

  Spec replaces the Service-based gateways[] array with a Gateway API
  ingressGateway block (gatewayClassName, listeners). Consumed by
  knative-stack (net-gateway-api) and dns-stack (gateway-httproute source).

  Implements [[tasks/istio-stack-ambient-rebuild]]

  BREAKING CHANGE: complete rewrite. Consumers must drop sidecar
  configuration and adopt ambient (namespace label istio.io/dataplane-mode:
  ambient). spec.gateways[] removed; configure ingress via
  spec.ingressGateway. PeerAuthentication is no longer required or rendered.

* ci: replace deleted examples (ha, local) with with-aws-lbc in workflow matrices (by @patrickleet)

* fix(e2e): split providerConfigRef into helm/kubernetes refs to match new schema (by @patrickleet)

* fix(e2e): disable ingressGateway in e2e (kind cluster lacks Gateway API CRDs) (by @patrickleet)


See full diff: [v0.13.0...v1.0.0](https://github.com/hops-ops/istio-stack/compare/v0.13.0...v1.0.0)

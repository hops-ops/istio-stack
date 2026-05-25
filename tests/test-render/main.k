import models.ai.com.ops.hops.v1alpha1 as stacksv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

# ==============================================================================
# Unit tests for IstioStack XRD (ambient + Gateway API)
#
# Philosophy: test YOUR API, not the chart's internals.
# - render/validate already checks provider schema correctness
# - Tests verify XRD spec fields produce the expected composed-resource shape
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: minimal claim renders the three core Helm releases (base, istiod,
    # ztunnel) in ambient profile, plus the platform Gateway by default.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-renders-ambient-control-plane"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec.clusterName = "my-cluster"
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-base"
                    spec.forProvider = {
                        chart = {
                            name = "base"
                            repository = "https://istio-release.storage.googleapis.com/charts"
                            version = "1.29.2"
                        }
                        namespace = "istio-system"
                    }
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istiod"
                    spec.forProvider = {
                        chart.name = "istiod"
                        chart.version = "1.29.2"
                        namespace = "istio-system"
                        values = {
                            profile = "ambient"
                            pilot.resources.requests = {cpu = "23m", memory = "121Mi"}
                        }
                    }
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-ztunnel"
                    spec.forProvider = {
                        chart.name = "ztunnel"
                        chart.version = "1.29.2"
                        namespace = "istio-system"
                        values.resources.requests = {cpu = "35m", memory = "100Mi"}
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 2: chartVersion override applies to base, istiod, AND ztunnel.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "chart-version-applies-to-all-three-releases"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec = {
                    clusterName = "my-cluster"
                    chartVersion = "1.30.0"
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-base"
                    spec.forProvider.chart.version = "1.30.0"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istiod"
                    spec.forProvider.chart.version = "1.30.0"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-ztunnel"
                    spec.forProvider.chart.version = "1.30.0"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 3: ingressGateway emits a Gateway resource with the configured
    # listeners and the requested gatewayClassName.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "ingress-gateway-emits-gateway-resource"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec = {
                    clusterName = "my-cluster"
                    ingressGateway = {
                        enabled = True
                        name = "edge"
                        namespace = "edge-ingress"
                        gatewayClassName = "istio"
                        listeners = [{
                            name = "https"
                            hostname = "*.example.com"
                            port = 443
                            protocol = "HTTPS"
                            tls.mode = "Terminate"
                        }]
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-gateway"
                    spec.forProvider.manifest = {
                        apiVersion = "gateway.networking.k8s.io/v1"
                        kind = "Gateway"
                        metadata = {
                            name = "edge"
                            namespace = "edge-ingress"
                        }
                        spec = {
                            gatewayClassName = "istio"
                            listeners = [{
                                name = "https"
                                hostname = "*.example.com"
                                port = 443
                                protocol = "HTTPS"
                                tls.mode = "Terminate"
                            }]
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 4: ingressGateway.enabled=false drops the Gateway + ingress namespace.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "ingress-gateway-disabled-skips-gateway-resource"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec = {
                    clusterName = "my-cluster"
                    ingressGateway.enabled = False
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istiod"
                }
                {
                    apiVersion = "hops.ops.com.ai/v1alpha1"
                    kind = "IstioStack"
                    metadata.name = "test"
                    status.gateway.ready = False
                }
            ]
        }
    }

    # ==========================================================================
    # Test 5: awsLoadBalancerController.enabled puts NLB annotations on the
    # Gateway's spec.infrastructure.annotations (Istio propagates them to the
    # auto-created Service so the LBC provisions an NLB).
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "aws-lbc-annotations-on-gateway-infrastructure"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec = {
                    clusterName = "my-cluster"
                    ingressGateway = {
                        enabled = True
                        name = "platform"
                        listeners = [{
                            name = "https"
                            hostname = "*.example.com"
                            port = 443
                            protocol = "HTTPS"
                            tls.mode = "Terminate"
                        }]
                    }
                    awsLoadBalancerController = {
                        enabled = True
                        scheme = "internet-facing"
                        targetType = "ip"
                        crossZoneEnabled = True
                        releaseRef.name = "lbc-release"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-gateway"
                    spec.forProvider.manifest.spec.infrastructure.annotations = {
                        "service.beta.kubernetes.io/aws-load-balancer-type" = "external"
                        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
                        "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
                        "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"
                        "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 6a: single HTTP extensionProvider renders into meshConfig with all
    # typed fields (service/port/path/headers/timeout/statusOnError).
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "extension-providers-http-renders-meshconfig"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec = {
                    clusterName = "my-cluster"
                    extensionProviders = [{
                        name = "observe-oauth2-proxy"
                        envoyExtAuthzHttp = {
                            service = "oauth2-proxy.observe.svc.cluster.local"
                            port = 4180
                            pathPrefix = "/oauth2/auth"
                            timeout = "1s"
                            includeRequestHeadersInCheck = ["authorization", "cookie"]
                            headersToUpstreamOnAllow = ["authorization", "x-auth-request-user"]
                            statusOnError = "403"
                        }
                    }]
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istiod"
                    spec.forProvider.values.meshConfig.extensionProviders = [{
                        name = "observe-oauth2-proxy"
                        envoyExtAuthzHttp = {
                            service = "oauth2-proxy.observe.svc.cluster.local"
                            port = 4180
                            pathPrefix = "/oauth2/auth"
                            timeout = "1s"
                            includeRequestHeadersInCheck = ["authorization", "cookie"]
                            headersToUpstreamOnAllow = ["authorization", "x-auth-request-user"]
                            statusOnError = "403"
                        }
                    }]
                }
                {
                    apiVersion = "hops.ops.com.ai/v1alpha1"
                    kind = "IstioStack"
                    metadata.name = "test"
                    status.extensionProviders.configured = ["observe-oauth2-proxy"]
                }
            ]
        }
    }

    # ==========================================================================
    # Test 6b: single gRPC extensionProvider renders the envoyExtAuthzGrpc
    # block (different shape: failOpen instead of HTTP header lists).
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "extension-providers-grpc-renders-meshconfig"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec = {
                    clusterName = "my-cluster"
                    extensionProviders = [{
                        name = "policy-engine"
                        envoyExtAuthzGrpc = {
                            service = "opa.policy.svc.cluster.local"
                            port = 9191
                            timeout = "250ms"
                            failOpen = False
                        }
                    }]
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istiod"
                    spec.forProvider.values.meshConfig.extensionProviders = [{
                        name = "policy-engine"
                        envoyExtAuthzGrpc = {
                            service = "opa.policy.svc.cluster.local"
                            port = 9191
                            timeout = "250ms"
                            failOpen = False
                        }
                    }]
                }
            ]
        }
    }

    # ==========================================================================
    # Test 6c: multiple extensionProviders render in order; status.configured
    # echoes the registered names.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "extension-providers-multiple-render-in-order"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec = {
                    clusterName = "my-cluster"
                    extensionProviders = [
                        {
                            name = "observe-oauth2-proxy"
                            envoyExtAuthzHttp = {
                                service = "oauth2-proxy.observe.svc.cluster.local"
                                port = 4180
                            }
                        }
                        {
                            name = "knative-oauth2-proxy"
                            envoyExtAuthzHttp = {
                                service = "oauth2-proxy.knative.svc.cluster.local"
                                port = 4180
                            }
                        }
                    ]
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istiod"
                    spec.forProvider.values.meshConfig.extensionProviders = [
                        {
                            name = "observe-oauth2-proxy"
                            envoyExtAuthzHttp = {
                                service = "oauth2-proxy.observe.svc.cluster.local"
                                port = 4180
                            }
                        }
                        {
                            name = "knative-oauth2-proxy"
                            envoyExtAuthzHttp = {
                                service = "oauth2-proxy.knative.svc.cluster.local"
                                port = 4180
                            }
                        }
                    ]
                }
                {
                    apiVersion = "hops.ops.com.ai/v1alpha1"
                    kind = "IstioStack"
                    metadata.name = "test"
                    status.extensionProviders.configured = ["observe-oauth2-proxy", "knative-oauth2-proxy"]
                }
            ]
        }
    }

    # ==========================================================================
    # Test 6d: empty extensionProviders list leaves meshConfig unchanged
    # (no extensionProviders key emitted) and status.configured is empty.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "extension-providers-empty-leaves-meshconfig-clean"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec.clusterName = "my-cluster"
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istiod"
                    spec.forProvider.values.meshConfig = {
                        accessLogFile = "/dev/stdout"
                    }
                }
                {
                    apiVersion = "hops.ops.com.ai/v1alpha1"
                    kind = "IstioStack"
                    metadata.name = "test"
                    status.extensionProviders = {
                        configured = []
                        ready = False
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 7: providerConfigRefs default to clusterName.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "provider-config-refs-default-to-cluster-name"
        spec = {
            compositionPath = "apis/istiostacks/composition.yaml"
            xrdPath = "apis/istiostacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.IstioStack {
                metadata.name = "test"
                spec.clusterName = "prod-cluster"
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-istiod"
                    spec.providerConfigRef = {
                        name = "prod-cluster"
                        kind = "ProviderConfig"
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-gateway"
                    spec.providerConfigRef = {
                        name = "prod-cluster"
                        kind = "ProviderConfig"
                    }
                }
            ]
        }
    }
]

items = _items

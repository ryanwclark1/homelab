local ingress(name, namespace, specs) = {
  apiVersion: 'traefik.io/v1alpha1',
  kind: 'IngressRoute',
  metadata: {
    name: name,
    namespace: namespace,
    // annotations: {
    //   'kubernetes.io/ingress.class': 'traefik-external',
    //   'traefik.ingress.kubernetes.io/router.entrypoints': 'websecure',
    //   'traefik.ingress.kubernetes.io/router.tls': 'true',
    //   'traefik.ingress.kubernetes.io/router.tls.certresolver': 'letsencrypt',
    // },
  },
  spec: specs,
};

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/external-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/pyrra.libsonnet') +
{
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
    grafana+:: {
      config+: {
        sections+: {
          server+: {
            root_url: 'http://grafana.techcasa.io/',
          },
        },
      },
    },
  },
  // Configure External URL's per application
  alertmanager+:: {
    alertmanager+: {
      spec+: {
        externalUrl: 'http://alertmanager.techcasa.io',
      },
    },
  },
  prometheus+:: {
    prometheus+: {
      spec+: {
        externalUrl: 'http://prometheus.techcasa.io',
      },
    },
  },
  // Create ingress objects per application
  ingress+:: {
    'alertmanager-main': ingress(
      'alertmanager-main',
      $.values.common.namespace,
      {
        entryPoints: [
          'web',
          'websecure'
        ],
        routes: [{
          kind: 'Rule',
          match: 'Host(`alertmanager.techcasa.io`)',
          services: [{
            name: 'alertmanager-main',
            port: 9093,
            namespace: $.values.common.namespace,
          }],
        }],
      },
    ),
    grafana: ingress(
      'grafana',
      $.values.common.namespace,
      {
        entryPoints: [
          'web',
          'websecure'
        ],
        routes: [{
          kind: 'Rule',
          match: 'Host(`grafana.techcasa.io`) && Path(`/login`)',
          services: [{
            name: 'grafana',
            port: 3000,
            namespace: $.values.common.namespace,
          }],
        }],
      },
    ),
    'prometheus-k8s': ingress(
      'prometheus-k8s',
      $.values.common.namespace,
      {
        entryPoints: [
          'web',
          'websecure'
        ],
        routes: [{
          kind: 'Rule',
          match: 'Host(`prometheus.techcasa.io`)',
          services: [{
            name: 'prometheus-k8s',
            port: 8080,
            namespace: $.values.common.namespace,
          }],
        }],
      },
    ),
  },
};
// + {
//   // Create basic auth secret - replace 'auth' file with your own
//   ingress+:: {
//     'basic-auth-secret': {
//       apiVersion: 'v1',
//       kind: 'Secret',
//       metadata: {
//         name: 'basic-auth',
//         namespace: $.values.common.namespace,
//       },
//       data: { auth: std.base64(importstr 'auth') },
//       type: 'Opaque',
//     },
//   },
// };


{ [name + '-ingress']: kp.ingress[name] for name in std.objectFields(kp.ingress) }
{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// { 'setup/pyrra-slo-CustomResourceDefinition': kp.pyrra.crd } +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
// { ['pyrra-' + name]: kp.pyrra[name] for name in std.objectFields(kp.pyrra) if name != 'crd' } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) }

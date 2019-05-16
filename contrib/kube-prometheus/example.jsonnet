local kp = (import 'kube-prometheus/kube-prometheus.libsonnet') +
           (import 'kube-prometheus/kube-prometheus-tolerations.libsonnet') +
           (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') + {
  _config+:: {
    namespace: 'kubesphere-monitoring-system',
    etcd+:: {
      ips: ['127.0.0.1'],
      clientCA: importstr 'examples/etcd-client-ca.crt',
      clientKey: importstr 'examples/etcd-client.key',
      clientCert: importstr 'examples/etcd-client.crt',
      serverName: 'etcd.kube-system.svc.cluster.local',
    },
  },
};

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) }
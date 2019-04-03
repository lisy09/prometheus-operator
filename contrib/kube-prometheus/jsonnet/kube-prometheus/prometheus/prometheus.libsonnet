local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';

{
  _config+:: {
    namespace: 'default',

    versions+:: {
      prometheus: 'v2.5.0',
    },

    imageRepos+:: {
      prometheus: 'dockerhub.qingcloud.com/prometheus/prometheus',
    },

    alertmanager+:: {
      name: 'main',
    },

    prometheus+:: {
      name: 'k8s',
      systemName: 'k8s-system',
      replicas: 1,
      rules: {},
      renderedRules: {},
      namespaces: ['default', 'kube-system', 'istio-system', $._config.namespace],
      retention: '7d',
      scrapeInterval: '1m',
      query: {
        maxConcurrency: 200 
      },
      storage: {
        volumeClaimTemplate: {
          spec: {
            resources: {
              requests: {
                storage: '20Gi',
              },
            },
          },
        },
      },
    },
  },

  prometheus+:: {
    serviceAccount:
      local serviceAccount = k.core.v1.serviceAccount;

      serviceAccount.new('prometheus-' + $._config.prometheus.name) +
      serviceAccount.mixin.metadata.withNamespace($._config.namespace),
    service:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local prometheusPort = servicePort.newNamed('web', 9090, 'web');

      service.new('prometheus-' + $._config.prometheus.name, { app: 'prometheus', prometheus: $._config.prometheus.name }, prometheusPort) +
      service.mixin.spec.withSessionAffinity('ClientIP') +
      service.mixin.metadata.withNamespace($._config.namespace) +
      service.mixin.metadata.withLabels({ prometheus: $._config.prometheus.name }) +
      service.mixin.spec.withClusterIp('None'),
    serviceSystem:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local prometheusPort = servicePort.newNamed('web', 9090, 'web');

      service.new('prometheus-' + $._config.prometheus.systemName, { app: 'prometheus', prometheus: $._config.prometheus.systemName }, prometheusPort) +
      service.mixin.spec.withSessionAffinity('ClientIP') +
      service.mixin.metadata.withNamespace($._config.namespace) +
      service.mixin.metadata.withLabels({ prometheus: $._config.prometheus.systemName }) +
      service.mixin.spec.withClusterIp('None'),
    serviceKubeScheduler:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local kubeSchedulerServicePort = servicePort.newNamed('http-metrics', 10251, 10251);

      service.new('kube-scheduler', null, kubeSchedulerServicePort) +
      service.mixin.metadata.withNamespace('kube-system') +
      service.mixin.metadata.withLabels({ 'k8s-app': 'kube-scheduler' }) +
      service.mixin.spec.withClusterIp('None') +
      service.mixin.spec.withSelector({ 'component': 'kube-scheduler' }),
    serviceKubeControllerManager:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local kubeControllerManagerServicePort = servicePort.newNamed('http-metrics', 10252, 10252);

      service.new('kube-controller-manager', null, kubeControllerManagerServicePort) +
      service.mixin.metadata.withNamespace('kube-system') +
      service.mixin.metadata.withLabels({ 'k8s-app': 'kube-controller-manager' }) +
      service.mixin.spec.withClusterIp('None') +
      service.mixin.spec.withSelector({ 'component': 'kube-controller-manager' }),

    [if $._config.prometheus.rules != null && $._config.prometheus.rules != {} then 'rules']:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'PrometheusRule',
        metadata: {
          labels: {
            prometheus: $._config.prometheus.name,
            role: 'alert-rules',
          },
          name: 'prometheus-' + $._config.prometheus.name + '-rules',
          namespace: $._config.namespace,
        },
        spec: {
          groups: $._config.prometheus.rules.groups,
        },
      },
    roleBindingSpecificNamespaces:
      local roleBinding = k.rbac.v1.roleBinding;

      local newSpecificRoleBinding(namespace) =
        roleBinding.new() +
        roleBinding.mixin.metadata.withName('prometheus-' + $._config.prometheus.name) +
        roleBinding.mixin.metadata.withNamespace(namespace) +
        roleBinding.mixin.roleRef.withApiGroup('rbac.authorization.k8s.io') +
        roleBinding.mixin.roleRef.withName('prometheus-' + $._config.prometheus.name) +
        roleBinding.mixin.roleRef.mixinInstance({ kind: 'Role' }) +
        roleBinding.withSubjects([{ kind: 'ServiceAccount', name: 'prometheus-' + $._config.prometheus.name, namespace: $._config.namespace }]);

      local roleBindigList = k.rbac.v1.roleBindingList;
      roleBindigList.new([newSpecificRoleBinding(x) for x in $._config.prometheus.namespaces]),
    clusterRole:
      local clusterRole = k.rbac.v1.clusterRole;
      local policyRule = clusterRole.rulesType;

      local nodeMetricsRule = policyRule.new() +
                              policyRule.withApiGroups(['']) +
                              policyRule.withResources(['nodes/metrics']) +
                              policyRule.withVerbs(['get']);

      local metricsRule = policyRule.new() +
                          policyRule.withNonResourceUrls('/metrics') +
                          policyRule.withVerbs(['get']);

      local rules = [nodeMetricsRule, metricsRule];

      clusterRole.new() +
      clusterRole.mixin.metadata.withName('prometheus-' + $._config.prometheus.name) +
      clusterRole.withRules(rules),
    roleConfig:
      local role = k.rbac.v1.role;
      local policyRule = role.rulesType;

      local configmapRule = policyRule.new() +
                            policyRule.withApiGroups(['']) +
                            policyRule.withResources([
                              'configmaps',
                            ]) +
                            policyRule.withVerbs(['get']);

      role.new() +
      role.mixin.metadata.withName('prometheus-' + $._config.prometheus.name + '-config') +
      role.mixin.metadata.withNamespace($._config.namespace) +
      role.withRules(configmapRule),
    roleBindingConfig:
      local roleBinding = k.rbac.v1.roleBinding;

      roleBinding.new() +
      roleBinding.mixin.metadata.withName('prometheus-' + $._config.prometheus.name + '-config') +
      roleBinding.mixin.metadata.withNamespace($._config.namespace) +
      roleBinding.mixin.roleRef.withApiGroup('rbac.authorization.k8s.io') +
      roleBinding.mixin.roleRef.withName('prometheus-' + $._config.prometheus.name + '-config') +
      roleBinding.mixin.roleRef.mixinInstance({ kind: 'Role' }) +
      roleBinding.withSubjects([{ kind: 'ServiceAccount', name: 'prometheus-' + $._config.prometheus.name, namespace: $._config.namespace }]),
    clusterRoleBinding:
      local clusterRoleBinding = k.rbac.v1.clusterRoleBinding;

      clusterRoleBinding.new() +
      clusterRoleBinding.mixin.metadata.withName('prometheus-' + $._config.prometheus.name) +
      clusterRoleBinding.mixin.roleRef.withApiGroup('rbac.authorization.k8s.io') +
      clusterRoleBinding.mixin.roleRef.withName('prometheus-' + $._config.prometheus.name) +
      clusterRoleBinding.mixin.roleRef.mixinInstance({ kind: 'ClusterRole' }) +
      clusterRoleBinding.withSubjects([{ kind: 'ServiceAccount', name: 'prometheus-' + $._config.prometheus.name, namespace: $._config.namespace }]),
    roleSpecificNamespaces:
      local role = k.rbac.v1.role;
      local policyRule = role.rulesType;
      local coreRule = policyRule.new() +
                       policyRule.withApiGroups(['']) +
                       policyRule.withResources([
                         'nodes',
                         'services',
                         'endpoints',
                         'pods',
                       ]) +
                       policyRule.withVerbs(['get', 'list', 'watch']);

      local newSpecificRole(namespace) =
        role.new() +
        role.mixin.metadata.withName('prometheus-' + $._config.prometheus.name) +
        role.mixin.metadata.withNamespace(namespace) +
        role.withRules(coreRule);

      local roleList = k.rbac.v1.roleList;
      roleList.new([newSpecificRole(x) for x in $._config.prometheus.namespaces]),
    prometheus:
      local statefulSet = k.apps.v1beta2.statefulSet;
      local container = statefulSet.mixin.spec.template.spec.containersType;
      local resourceRequirements = container.mixin.resourcesType;
      local selector = statefulSet.mixin.spec.selectorType;

      local resources =
        resourceRequirements.new() +
        resourceRequirements.withRequests({ memory: '400Mi' });

      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'Prometheus',
        metadata: {
          name: $._config.prometheus.name,
          namespace: $._config.namespace,
          labels: {
            prometheus: $._config.prometheus.name,
          },
        },
        spec: {
          replicas: $._config.prometheus.replicas,
          retention: $._config.prometheus.retention,
          scrapeInterval: $._config.prometheus.scrapeInterval,
          query: $._config.prometheus.query,
          storage: $._config.prometheus.storage,
          version: $._config.versions.prometheus,
          baseImage: $._config.imageRepos.prometheus,
          serviceAccountName: 'prometheus-' + $._config.prometheus.name,
          serviceMonitorSelector: {matchExpressions: [{key: 'k8s-app', operator: 'In', values: ['kube-state-metrics', 'node-exporter', 'kubelet', 'prometheus-system']}]},
          serviceMonitorNamespaceSelector: {},
          nodeSelector: { 'beta.kubernetes.io/os': 'linux' },
          ruleSelector: selector.withMatchLabels({
            role: 'alert-rules',
            prometheus: $._config.prometheus.name,
          }),
          resources: resources,
          securityContext: {
            runAsUser: 0,
            runAsNonRoot: false,
            fsGroup: 0,
          },
        },
      },
    prometheusSystem:
      local statefulSet = k.apps.v1beta2.statefulSet;
      local container = statefulSet.mixin.spec.template.spec.containersType;
      local resourceRequirements = container.mixin.resourcesType;
      local selector = statefulSet.mixin.spec.selectorType;

      local resources =
        resourceRequirements.new() +
        resourceRequirements.withRequests({ memory: '400Mi' });

      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'Prometheus',
        metadata: {
          name: $._config.prometheus.systemName,
          namespace: $._config.namespace,
          labels: {
            prometheus: $._config.prometheus.systemName,
          },
        },
        spec: {
          replicas: $._config.prometheus.replicas,
          retention: $._config.prometheus.retention,
          scrapeInterval: $._config.prometheus.scrapeInterval,
          query: $._config.prometheus.query,
          storage: $._config.prometheus.storage,
          version: $._config.versions.prometheus,
          baseImage: $._config.imageRepos.prometheus,
          serviceAccountName: 'prometheus-' + $._config.prometheus.name,
          serviceMonitorSelector: {matchExpressions: [{key: 'k8s-app', operator: 'In', values: ['etcd', 'coredns', 'apiserver', 'prometheus', 'kube-scheduler', 'kube-controller-manager']}]},
          serviceMonitorNamespaceSelector: {},
          nodeSelector: { 'beta.kubernetes.io/os': 'linux' },
          ruleSelector: selector.withMatchLabels({
            role: 'alert-rules',
            prometheus: $._config.prometheus.name,
          }),
          resources: resources,
          securityContext: {
            runAsUser: 0,
            runAsNonRoot: false,
            fsGroup: 0,
          },
          additionalScrapeConfigs: {
            name: 'additional-scrape-configs',
            key: 'prometheus-additional.yaml',
          },
        },
      },
    serviceMonitor:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'prometheus',
          namespace: $._config.namespace,
          labels: {
            'k8s-app': 'prometheus',
          },
        },
        spec: {
          selector: {
            matchLabels: {
              prometheus: $._config.prometheus.name,
            },
          },
          endpoints: [
            {
              port: 'web',
              interval: '1m',
            },
          ],
        },
      },
    serviceMonitorSystem:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'prometheus-system',
          namespace: $._config.namespace,
          labels: {
            'k8s-app': 'prometheus-system',
          },
        },
        spec: {
          selector: {
            matchLabels: {
              prometheus: $._config.prometheus.systemName,
            },
          },
          endpoints: [
            {
              port: 'web',
              interval: '1m',
            },
          ],
        },
      },
    serviceMonitorKubeScheduler:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'kube-scheduler',
          namespace: $._config.namespace,
          labels: {
            'k8s-app': 'kube-scheduler',
          },
        },
        spec: {
          jobLabel: 'k8s-app',
          endpoints: [
            {
              port: 'http-metrics',
              interval: '1m',
            },
          ],
          selector: {
            matchLabels: {
              'k8s-app': 'kube-scheduler',
            },
          },
          namespaceSelector: {
            matchNames: [
              'kube-system',
            ],
          },
        },
      },
    serviceMonitorKubelet:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'kubelet',
          namespace: $._config.namespace,
          labels: {
            'k8s-app': 'kubelet',
          },
        },
        spec: {
          jobLabel: 'k8s-app',
          endpoints: [
            {
              port: 'https-metrics',
              scheme: 'https',
              interval: '1m',
              honorLabels: true,
              tlsConfig: {
                insecureSkipVerify: true,
              },
              bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
              metricRelabelings: [
                // Drop unused metrics
                {
                  sourceLabels: ['__name__'],
                  regex: 'reflector_.*|rest_client_.*|storage_operation_.*|apiserver_.*|http_.*|go_.*',
                  action: 'drop',
                },
              ],
            },
            {
              port: 'https-metrics',
              scheme: 'https',
              path: '/metrics/cadvisor',
              interval: '1m',
              honorLabels: true,
              tlsConfig: {
                insecureSkipVerify: true,
              },
              bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
              metricRelabelings: [
                // Drop container_* metrics with no image.
                {
                  sourceLabels: ['__name__', 'image'],
                  regex: 'container_([a-z_]+);',
                  action: 'drop',
                },

                // Drop a bunch of metrics which are disabled but still sent, see
                // https://github.com/google/cadvisor/issues/1925.
                {
                  sourceLabels: ['__name__'],
                  regex: 'container_cpu_usage_seconds_total|container_memory_usage_bytes|container_memory_cache|container_network_.+_bytes_total|container_memory_working_set_bytes',
                  action: 'keep',
                },
              ],
            },
          ],
          selector: {
            matchLabels: {
              'k8s-app': 'kubelet',
            },
          },
          namespaceSelector: {
            matchNames: [
              'kube-system',
            ],
          },
        },
      },
    serviceMonitorKubeControllerManager:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'kube-controller-manager',
          namespace: $._config.namespace,
          labels: {
            'k8s-app': 'kube-controller-manager',
          },
        },
        spec: {
          jobLabel: 'k8s-app',
          endpoints: [
            {
              port: 'http-metrics',
              interval: '1m',
              metricRelabelings: [
                // Only keep necessary metrics
                {
                  sourceLabels: ['__name__'],
                  regex: 'up',
                  action: 'keep',
                },
              ],
            },
          ],
          selector: {
            matchLabels: {
              'k8s-app': 'kube-controller-manager',
            },
          },
          namespaceSelector: {
            matchNames: [
              'kube-system',
            ],
          },
        },
      },
    serviceMonitorApiserver:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'kube-apiserver',
          namespace: $._config.namespace,
          labels: {
            'k8s-app': 'apiserver',
          },
        },
        spec: {
          jobLabel: 'component',
          selector: {
            matchLabels: {
              component: 'apiserver',
              provider: 'kubernetes',
            },
          },
          namespaceSelector: {
            matchNames: [
              'default',
            ],
          },
          endpoints: [
            {
              port: 'https',
              interval: '1m',
              scheme: 'https',
              tlsConfig: {
                caFile: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
                serverName: 'kubernetes',
              },
              bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
              metricRelabelings: [
                {
                  sourceLabels: ['__name__'],
                  regex: 'etcd_(debugging|disk|request|server).*',
                  action: 'drop',
                },
                {
                  sourceLabels: ['__name__'],
                  regex: 'apiserver_admission_controller_admission_latencies_seconds_.*',
                  action: 'drop',
                },
                {
                  sourceLabels: ['__name__'],
                  regex: 'apiserver_admission_step_admission_latencies_seconds_.*',
                  action: 'drop',
                },
              ],
            },
          ],
        },
      },
    serviceMonitorCoreDNS:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'coredns',
          namespace: $._config.namespace,
          labels: {
            'k8s-app': 'coredns',
          },
        },
        spec: {
          jobLabel: 'k8s-app',
          selector: {
            matchLabels: {
              'k8s-app': 'coredns',
            },
          },
          namespaceSelector: {
            matchNames: [
              'kube-system',
            ],
          },
          endpoints: [
            {
              port: 'metrics',
              interval: '1m',
              bearerTokenFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
            },
          ],
        },
      },
  },
}

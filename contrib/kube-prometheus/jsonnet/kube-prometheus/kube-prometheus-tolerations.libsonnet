local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local statefulSet = k.apps.v1beta2.statefulSet;
local toleration = statefulSet.mixin.spec.template.spec.tolerationsType;

{
  _config+:: {
    tolerations+:: [
      {
        key: 'dedicated',
        operator: 'Equal',
        value: 'monitoring',
        effect: 'NoSchedule',
      },
    ]
  },

  local withTolerations() = {
    tolerations: [
      toleration.new() +
      toleration.withKey(t.key) +
      toleration.withOperator(t.operator) + 
      toleration.withValue(t.value) +
      toleration.withEffect(t.effect),
      for t in $._config.tolerations
    ],
  },

  prometheus+: {
    prometheus+: {
      spec+:
        withTolerations(),
    },
    prometheusSystem+: {
      spec+:
        withTolerations(),
    },
  },
}

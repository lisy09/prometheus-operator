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
      toleration.new() + (
      if std.objectHas(t, 'key') then toleration.withKey(t.key) else toleration) + (
      if std.objectHas(t, 'operator') then toleration.withOperator(t.operator) else toleration) + (
      if std.objectHas(t, 'value') then toleration.withValue(t.value) else toleration) + (
      if std.objectHas(t, 'effect') then toleration.withEffect(t.effect) else toleration),
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

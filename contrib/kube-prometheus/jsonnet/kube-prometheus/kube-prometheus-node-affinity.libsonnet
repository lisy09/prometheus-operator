local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local statefulSet = k.apps.v1beta2.statefulSet;
local nodeAffinity = statefulSet.mixin.spec.template.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecutionType;
local matchExpression = nodeAffinity.mixin.preference.matchExpressionsType;

{
  local affinity(key) = {
    affinity+: {
      nodeAffinity: {
        preferredDuringSchedulingIgnoredDuringExecution: [
          nodeAffinity.new() + 
          nodeAffinity.withWeight(100) +
          nodeAffinity.mixin.preference.withMatchExpressions([
            matchExpression.new() +
            matchExpression.withKey(key) +
            matchExpression.withOperator('Exists'), 
          ]),
        ],
      },
    },
  },

  prometheus+: {
    prometheus+: {
      spec+:
        affinity('node-role.kubernetes.io/monitoring'),
    },
    prometheusSystem+: {
      spec+:
      affinity('node-role.kubernetes.io/monitoring'),
    },
  },
}

{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'general.rules',
        rules: [
          {
            alert: 'DeadMansSwitch',
            annotations: {
              message: 'This is a DeadMansSwitch meant to ensure that the entire alerting pipeline is functional.',
            },
            expr: 'vector(1)',
            labels: {
              severity: 'none',
            },
          },
        ],
      },
    ],
  },
}

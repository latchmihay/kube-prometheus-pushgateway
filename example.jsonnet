local kp =
  (import "prometheus-pushgateway/pushgateway.libsonnet") +
  {
    _config+:: {
      namespace: 'monitoring',
    },
  };

{ ['prometheus-pushgateway-' + name]: kp.pushgateway[name], for name in std.objectFields(kp.pushgateway) }
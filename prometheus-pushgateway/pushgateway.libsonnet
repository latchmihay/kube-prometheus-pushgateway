local k = import 'ksonnet/ksonnet.beta.4/k.libsonnet';

{
  _config+:: {
    namespace: 'default',

    versions+:: {
      pushgateway: 'v0.8.0',
    },

    imageRepos+:: {
      pushgateway: 'prom/pushgateway',
    },
  },

  pushgateway+:: {
    deployment:
      local deployment = k.apps.v1beta2.deployment;
      local container = deployment.mixin.spec.template.spec.containersType;
      local containerPort = container.portsType;
      local podSelector = deployment.mixin.spec.template.spec.selectorType;

      local port = 9091;
      local name = "prometheus-pushgateway";
      local podLabels = { app: 'prometheus-pushgateway' };

      local c =
        container.new('pushgateway', $._config.imageRepos.pushgateway + ':' + $._config.versions.pushgateway) +
        container.withPorts(containerPort.newNamed(port, 'metrics')) +
        container.mixin.resources.withRequests({ cpu: '50m', memory: '100Mi' }) +
        container.mixin.resources.withLimits({ cpu: '50m', memory: '100Mi' }) +
        container.mixin.livenessProbe.withInitialDelaySeconds(10) +
        container.mixin.livenessProbe.withTimeoutSeconds(10)+
        container.mixin.livenessProbe.httpGet.withPath("/#/status") +
        container.mixin.livenessProbe.httpGet.withPort(port) +
        container.mixin.readinessProbe.withInitialDelaySeconds(10) +
        container.mixin.readinessProbe.withTimeoutSeconds(10)+
        container.mixin.readinessProbe.httpGet.withPath("/#/status") +
        container.mixin.readinessProbe.httpGet.withPort(port);

      deployment.new('prometheus-pushgateway', 1, c, podLabels) +
      deployment.mixin.metadata.withNamespace($._config.namespace) +
      deployment.mixin.metadata.withLabels(podLabels) +
      deployment.mixin.spec.selector.withMatchLabels(podLabels),

    service:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local pushgatewayPort = servicePort.newNamed('http', 9091, 'http');

      service.new('prometheus-pushgateway', $.pushgateway.deployment.spec.selector.matchLabels, pushgatewayPort) +
      service.mixin.metadata.withNamespace($._config.namespace) +
      service.mixin.metadata.withLabels({ 'app': 'prometheus-pushgateway' }) +
      service.mixin.spec.withType('ClusterIP'),

    serviceMonitor:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: "prometheus-pushgateway",
          namespace: $._config.namespace,
          labels: {
            'prometheus': 'k8s',
          },
        },
        spec: {
          jobLabel: 'k8s-app',
          selector: {
            matchLabels: {
              "app": "prometheus-pushgateway"
            },
          },
          endpoints: [
            {
              port: 'http',
              honorLabels: true,
            },
          ],
        },
      },
  },
}

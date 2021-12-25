local k = import 'ksonnet/ksonnet.beta.4/k.libsonnet';

{
  _config+:: {
    namespace: 'pushgateway',

    versions+:: {
      pushgateway: 'v1.4.2',
    },

    imageRepos+:: {
      pushgateway: 'prom/pushgateway',
    },

    pushgateway+:: {
        name: "prometheus-pushgateway",
        port: 9091,
        labels: { app: $._config.pushgateway.name},
        cpu: "50m",
        memory: "100Mi"
    }
  },

  pushgateway+:: {
    deployment:
      local deployment = k.apps.v1.deployment;
      local container = deployment.mixin.spec.template.spec.containersType;
      local containerPort = container.portsType;
      local podSelector = deployment.mixin.spec.template.spec.selectorType;

      local c =
        container.new('pushgateway', $._config.imageRepos.pushgateway + ':' + $._config.versions.pushgateway) +
        container.withPorts(containerPort.newNamed($._config.pushgateway.port, 'metrics')) +
        container.mixin.resources.withRequests({ cpu: $._config.pushgateway.cpu, memory: $._config.pushgateway.memory }) +
        container.mixin.resources.withLimits({ cpu: $._config.pushgateway.cpu, memory: $._config.pushgateway.memory }) +
        container.mixin.livenessProbe.withInitialDelaySeconds(10) +
        container.mixin.livenessProbe.withTimeoutSeconds(10)+
        container.mixin.livenessProbe.httpGet.withPath("/#/status") +
        container.mixin.livenessProbe.httpGet.withPort($._config.pushgateway.port) +
        container.mixin.readinessProbe.withInitialDelaySeconds(10) +
        container.mixin.readinessProbe.withTimeoutSeconds(10)+
        container.mixin.readinessProbe.httpGet.withPath("/#/status") +
        container.mixin.readinessProbe.httpGet.withPort($._config.pushgateway.port);

      deployment.new($._config.pushgateway.name, 1, c, $._config.pushgateway.labels) +
      deployment.mixin.metadata.withNamespace($._config.namespace) +
      deployment.mixin.metadata.withLabels($._config.pushgateway.labels) +
      deployment.mixin.spec.selector.withMatchLabels($._config.pushgateway.labels),

    service:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local pushgatewayPort = servicePort.newNamed('http', $._config.pushgateway.port, 'metrics');

      service.new($._config.pushgateway.name, $.pushgateway.deployment.spec.selector.matchLabels, pushgatewayPort) +
      service.mixin.metadata.withNamespace($._config.namespace) +
      service.mixin.metadata.withLabels($._config.pushgateway.labels) +
      service.mixin.spec.withType('LoadBalancer'),

    serviceMonitor:
      {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: $._config.pushgateway.name,
          namespace: $._config.namespace,
          labels: {
            'prometheus': 'k8s',
          },
        },
        spec: {
          jobLabel: 'k8s-app',
          selector: {
            matchLabels: $._config.pushgateway.labels,
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

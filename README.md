# kube-prometheus-pushgateway
Kubernetes Prometheus Pushgateway in Jsonnet format as a reusable component.

It is aimed to be used and consumbed by [coreos/kube-prometheus](https://github.com/coreos/kube-prometheus)

## Usage

Use this package in your own infrastructure using [`jsonnet-bundler`](https://github.com/jsonnet-bundler/jsonnet-bundler):

```bash
jb install github.com/latchmihay/kube-prometheus-pushgateway/prometheus-pushgateway
```

An example of how to use it could be: (save as example.jsonnet)
```jsonnet
local kp =
  (import "prometheus-pushgateway/pushgateway.libsonnet") +
  {
    _config+:: {
      namespace: 'monitoring',
    },
  };

{ ['prometheus-pushgateway-' + name]: kp.pushgateway[name], for name in std.objectFields(kp.pushgateway) }
```

This builds a Prometheus Push Gateway stack

Simply run:

```bash
$ jsonnet -J vendor example.jsonnet
```

## Generate Yamls (Similar to the way kube-prometheus works)
```bash
go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
go get github.com/brancz/gojsontoyaml
cd prometheus-pushgateway && jb install && cd ..
rm -rf manifests
mkdir manifests
jsonnet -J prometheus-pushgateway/vendor  -m manifests example.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml; rm -f {}' -- {}
cat manifests/*
```

## Usage along side kube-prometheus
```bash
git clone https://github.com/coreos/kube-prometheus.git
cd kube-prometheus
jb install github.com/latchmihay/kube-prometheus-pushgateway/prometheus-pushgateway
cat > withPromGateway.jsonnet <<EOF
local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  (import "prometheus-pushgateway/pushgateway.libsonnet") +
  {
    _config+:: {
      namespace: 'monitoring',
    },
  };

{ ['prometheus-pushgateway-' + name]: kp.pushgateway[name], for name in std.objectFields(kp.pushgateway) } +
{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
EOF
./build.sh withPromGateway.jsonnet

# everything is at manifests folder
```

## Usage along side kube-prometheus in a container
```bash
git clone https://github.com/coreos/kube-prometheus.git
cd kube-prometheus
cat > withPromGateway.jsonnet <<EOF
local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  (import "prometheus-pushgateway/pushgateway.libsonnet") +
  {
    _config+:: {
      namespace: 'monitoring',
    },
  };

{ ['prometheus-pushgateway-' + name]: kp.pushgateway[name], for name in std.objectFields(kp.pushgateway) } +
{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
EOF

docker run --rm -v $(pwd):$(pwd) --workdir $(pwd) quay.io/coreos/jsonnet-ci jb install github.com/latchmihay/kube-prometheus-pushgateway/prometheus-pushgateway

docker run --rm -v $(pwd):$(pwd) --workdir $(pwd) quay.io/coreos/jsonnet-ci ./build.sh withPromGateway.jsonnet

# all the yamls are in the manifests folder
```
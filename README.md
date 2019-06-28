# kube-prometheus-pushgateway
Kubernetes Prometheus Pushgateway in Jsonnet format as a reusable component.

It is aimed to be used and consumbed by [coreos/kube-prometheus](https://github.com/coreos/kube-prometheus)

## Usage

Use this package in your own infrastructure using [`jsonnet-bundler`](https://github.com/jsonnet-bundler/jsonnet-bundler):

```bash
jb install github.com/latchmihay/kube-prometheus-pushgateway/pushgateway
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
jb install github.com/latchmihay/kube-prometheus-pushgateway/pushgateway
cat > withPromGateway.jsonet <<EOF
local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-managed-cluster.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-node-ports.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-thanos.libsonnet') +
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
./build.sh withPromGateway.jsonet

# everything is at manifests folder
```
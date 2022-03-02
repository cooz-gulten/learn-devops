# JAEGER with Elastic Cluster

Requirements:
- Kubernetes Cluster
- Helm

## Install Elastic + Kibana

### Bitnami Elastic

Add Helm repo
```
helm repo add bitnami https://charts.bitnami.com/bitnami
```
Install Elastic
```sh
helm upgrade -i elk bitnami/elasticsearch \
--set global.kibanaEnabled=true
```
OR Install Elastic Search + TLS
```sh
helm upgrade -i elk bitnami/elasticsearch --values values-elk.yaml
```

## Install Jaeger

1. Install Jaeger for Elastic without TLS
```sh
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.cassandra=false \
  --set storage.type=elasticsearch \
  --set storage.elasticsearch.host=elk-coordinating-only \
  --set storage.elasticsearch.port=9200
```

1. Install Jaeger for Elastic with TLS Enabled

get secret "**elk-coordinating-only-crt**"

create file tls.crt from value "tls.crt"
create file tls.key from value "tls.key"

Create PEM file

```sh
cat tls.crt tls.key > es.pem
```
Generate configmap jaeger-tls:
```
keytool -import -trustcacerts -keystore trust.store -storepass changeit -alias es-root -file es.pem
kubectl create configmap jaeger-tls --from-file=trust.store --from-file=es.pem
```

2. 

Add Helm repo
```sh
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
```
Install
```sh
helm upgrade -i jaeger jaegertracing/jaeger --values values-jaeger.yaml
```

## Install Elastic APM

```
helm repo add elastic https://helm.elastic.co
helm repo update

helm upgrade -i elastic-apm elastic/apm-server --values values-apm.yaml
```

## Istio

```
oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z default -n istio-system
oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-egressgateway-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-ingressgateway-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-cleanup-old-ca-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-sidecar-injector-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-galley-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-security-post-install-account -n istio-system
```

## Uninstall

```sh
helm delete elk
helm delete jaeger
```



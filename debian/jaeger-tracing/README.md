---
title: Jaeger Tracing client connect with Open Telemetry
description: How to send tracing via opentelemetry to Jaeger Tracing.
author: afandy
linkedin: https://www.linkedin.com/in/afandylamusu/
gul.author: afandy
gul.date: 03/10/2022
gul.custom: devops-jaegertracing
gul.topic: tutorial
---
# Jaeger Tracing client connect with Open Telemetry

Artikel ini membahas bagaimana memonitor `http-requests` aplikasi kita dengan Jaeger Tracing. 

Untuk mempelajari lebih lanjut tentang jaeger silahka kunjungi [Dokumentasi Jaeger](https://www.jaegertracing.io/docs/1.32/)

## Run Jaeger with Docker Compose

Pastikan anda memiliki `docker-engine` di pc/laptop. Jika belum silahkan download dan install [**docker for desktop**](https://docs.docker.com/get-docker/)

Jalankan seluruh service di local pc dengan command docker compose.

```sh
docker-compose up -d
```

## Install Elastic Search



## Run Jaeger in Kubernetes

### Prerequisites

- Helm 3.0+

### Installing the Chart

Daftarkan open-telemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts &&\
helm repo update


```

Install chart dengan nama release my-tracing, dengan command berikut:

```console
helm upgrade -i my-tracing open-telemetry/opentelemetry-collector -f otel-values.yaml
```


## Next steps


## Sources
- [Open Telemetry Docker Compose](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/examples/tracing)
- [Open Telemetry Helm Charts](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector)
- https://staffordwilliams.com/blog/2021/02/01/minimal-elasticsearch-resources-in-kubernetes/
- https://github.com/eqfarhad/distributed_tracing
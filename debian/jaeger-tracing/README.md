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

Artikel ini membahas Bagaimana memonitor `http-requests` aplikasi kita dengan Jaeger Tracing. 

Untuk mempelajari lebih lanjut tentang jaeger silahka kunjungi [Dokumentasi Jaeger](https://www.jaegertracing.io/docs/1.32/)

## Run Jaeger with Docker Compose

Pastikan anda memiliki `docker-engine` di pc/laptop. Jika belum silahkan download dan install [**docker for desktop**](https://docs.docker.com/get-docker/)

Jalankan seluruh service di local pc dengan command docker compose.

```sh
docker-compose up -d
```

## Run Jaeger in Kubernetes

### Prerequisites

- Helm 3.0+

### Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-opentelemetry-collector, run the following command:

```console
helm upgrade my-tracing open-telemetry/opentelemetry-collector
```


## Next steps

Get started developing .NET applications by following a [step-by-step tutorial](../standard/get-started.md) or by watching [.NET 101 videos](https://www.youtube.com/playlist?list=PLdo4fOcmZ0oWoazjhXQzBKMrFuArxpW80) on YouTube.

## Sources
- https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/examples/tracing
- https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector
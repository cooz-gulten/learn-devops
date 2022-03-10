# Minio Distributed

## Install

```sh
helm upgrade -i minio3 minio --set mode=distributed
```

## Bucket Replication

1. You have another distributed Minio Server.
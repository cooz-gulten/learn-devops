# Openfaas with Istio

[Source](https://www.openfaas.com/blog/istio-functions/)

## Overview

Service meshes have become popular add-ons for Kubernetes, so much so that they have their own ServiceMeshCon days at KubeCon, the official Kubernetes conference.

A service mesh can be used to apply policies to network communication, encrypt traffic between endpoints and for advanced routing.

**Istio** is one of the most popular service meshes available for use with Kubernetes and with help from the team at Google, we’ve recently updated the support and documentation for using Istio with OpenFaaS.

![](images/arch.svg)

| **Istio’s mesh created by injecting Envoy proxies into each Pod to encapsulate networking**

The value for users is:

- Providing more advanced and flexible policy than Kubernetes’ NetworkPolicies
- Encrypting traffic between all OpenFaaS components and functions for “zero trust”
- Providing advanced networking like retries, and weighting for canaries and gradual rollouts of new functions

| There are many service mesh products available. Other popular options include: Linkerd, Kuma and Consul.
| You may also like the workshop we created to show how to do mutual TLS and traffic shifting with OpenFaaS and Linkerd.

## TUTORIAL

**Tools**
- Minikube
- Parallel Desktop Pro
- Arkade

### Start Minikube

```
minikube config set driver parallels 

minikube config set disk-size 64000MB
minikube config set cpus 4
minikube config set memory 16384
minikube start
```

### Install Istio
Once up and running, install Istio:

```
arkade install istio
```

### Install Openfaas
The `gateway.directFunctions=true` flag prevents OpenFaaS from trying to do its own endpoint load-balancing between function replicas, and defers to Envoy instead. Envoy is configured for each pod by Istio and handles routing and retries.

The `istio.mtls` flag is optional, but when set encrypts the traffic between each of the pods in the openfaas and openfaas-fn namespace.

```
arkade install openfaas \
  --set gateway.directFunctions=true \
  --set istio.mtls=true
```

At this point everything is configured and you can use OpenFaaS.

### Access OpenFaaS with an Istio Gateway

Create an Istio Gateway so that we can connect to the OpenFaaS Gateway and log in.


```
# gateway.yaml
cat > gateway.yaml <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: openfaas-gateway
  namespace: openfaas
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: openfaas-api
  namespace: openfaas
spec:
  hosts:
  - "*"
  gateways:
  - openfaas-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: gateway
        port:
          number: 8080
EOF

kubectl apply -f gateway.yaml
```

Port-forward the Istio Ingress Gateway:

```
kubectl port-forward -n istio-system \
  svc/istio-ingressgateway \
  8080:80 \
  8443:443 &
```

Log in:

```
PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo)

echo -n $PASSWORD | faas-cli login --username admin --password-stdin
```

### Deploy a test function

```
# Find something you are interested in with:
faas-cli store list

# Deploy one of the functions
faas-cli store deploy nodeinfo
```

Invoke the function via the Istio Ingress gateway:

```
echo | faas-cli invoke nodeinfo
```

Describe the Function’s deployment, so you can see that the Istio proxy (Envoy) has been configured:

```
kubectl describe pod -n openfaas-fn

Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  48s   default-scheduler  Successfully assigned openfaas-fn/nodeinfo-857d9c469b-ww66k to openfaas-istio-control-plane
  Normal  Pulling    47s   kubelet            Pulling image "docker.io/istio/proxyv2:1.9.1"
  Normal  Pulled     46s   kubelet            Successfully pulled image "docker.io/istio/proxyv2:1.9.1" in 938.690323ms
  Normal  Created    46s   kubelet            Created container istio-init
  Normal  Started    46s   kubelet            Started container istio-init
  Normal  Pulling    46s   kubelet            Pulling image "ghcr.io/openfaas/nodeinfo:latest"
  Normal  Pulled     38s   kubelet            Successfully pulled image "ghcr.io/openfaas/nodeinfo:latest" in 8.160064746s
  Normal  Created    38s   kubelet            Created container nodeinfo
  Normal  Started    38s   kubelet            Started container nodeinfo
  Normal  Pulling    38s   kubelet            Pulling image "docker.io/istio/proxyv2:1.9.1"
  Normal  Pulled     37s   kubelet            Successfully pulled image "docker.io/istio/proxyv2:1.9.1" in 925.80937ms
  Normal  Created    37s   kubelet            Created container istio-proxy
  Normal  Started    37s   kubelet            Started container istio-proxy
```

You can also use istioctl to explore the status of the proxy:

```
~/.arkade/bin/istioctl proxy-status
NAME                                                   CDS        LDS        EDS        RDS        ISTIOD                      VERSION
alertmanager-7cb8f6487d-ch4fp.openfaas                 SYNCED     SYNCED     SYNCED     SYNCED     istiod-865fd47fcc-24vdp     1.9.1
basic-auth-plugin-565b7cbc48-h9t8d.openfaas            SYNCED     SYNCED     SYNCED     SYNCED     istiod-865fd47fcc-24vdp     1.9.1
gateway-5fb6bf58dd-74j8c.openfaas                      SYNCED     SYNCED     SYNCED     SYNCED     istiod-865fd47fcc-24vdp     1.9.1
istio-ingressgateway-5bcdc9b77f-knrpz.istio-system     SYNCED     SYNCED     SYNCED     SYNCED     istiod-865fd47fcc-24vdp     1.9.1
nats-76b689f8d8-mkwtl.openfaas                         SYNCED     SYNCED     SYNCED     SYNCED     istiod-865fd47fcc-24vdp     1.9.1
nodeinfo-857d9c469b-ww66k.openfaas-fn                  SYNCED     SYNCED     SYNCED     SYNCED     istiod-865fd47fcc-24vdp     1.9.1
prometheus-5664d7cbb9-kchff.openfaas                   SYNCED     SYNCED     SYNCED     SYNCED     istiod-865fd47fcc-24vdp     1.9.1
queue-worker-5b7c5b898d-fqkv5.openfaas                 SYNCED     SYNCED     SYNCED     SYNCED     istiod-865fd47fcc-24vdp     1.9.1
```

Running the following will open a dashboard, and you can run istioctl dashboard --help to see how to launch the Grafana or Envoy UI.

```
istioctl dashboard controlz deployment/istiod.istio-system
```

You can detect the presence of Envoy within your function by looking at the HTTP headers passed on:

```
faas-cli deploy \
  --name env \
  --image ghcr.io/openfaas/alpine:latest \
  --fprocess="env"

echo | faas-cli invoke env

HOSTNAME=env-58bd77889c-k8h76
Http_User_Agent=curl/7.68.0
Http_X_Forwarded_Host=faas.o6s.io
Http_X_B3_Spanid=2b4e331b2d6ce20b
Http_X_B3_Parentspanid=9d7bf1a36bdb2462
Http_X_B3_Sampled=0
Http_X_Envoy_Attempt_Count=1
Http_Accept=*/*
Http_X_Call_Id=64d75811-958e-4865-9694-b09806a3685e
Http_X_Forwarded_Proto=https
Http_X_Request_Id=aeffe73e-eee1-431a-af96-8259bca8facb
Http_Accept_Encoding=gzip
Http_X_B3_Traceid=657ff91f248b8ca562effe793263c602
Http_X_Forwarded_For=10.244.0.16
Http_X_Start_Time=1621427147315051123
Http_Content_Length=0
Http_X_Envoy_Internal=true
Http_X_Forwarded_Client_Cert=By=spiffe://cluster.local/ns/openfaas-fn/sa/default;Hash=0fcbc9f3aad0c8bc4b122e9f972a278f35865c92f3bdbdb9312162ada17ea3cc;Subject="";URI=spiffe://cluster.local/ns/openfaas/sa/openfaas-controller
Http_Method=GET
Http_ContentLength=0
Http_Path=/
Http_Host=env.openfaas-fn.svc.cluster.local:8080
```

## Going Further

### Measuring the effects

There is a cost involved with installing a service mesh like Istio. There will be additional RAM required, additional control-plane components to configure and keep updated, along with additional latency and cold-start times for scaling functions from zero.

If you would like to understand the quiescent load on the cluster, you can install the Kubernetes metrics-server through arkade:

```
minikube addons enable metrics-server

# Wait a few minutes for data collection, then run:
kubectl top node
kubectl top pod -A
```

These are my results after having completed the whole tutorial including: KinD, cert-manager, openfaas, inlets-operator and the metrics-server itself.

```
kubectl top node
NAME                           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
openfaas-istio-control-plane   399m         4%     1693Mi          5% 

kubectl top pod -A
NAMESPACE            NAME                                                   CPU(cores)   MEMORY(bytes)   
cert-manager         cert-manager-7998c69865-ljf2h                          7m           22Mi            
cert-manager         cert-manager-cainjector-7b744d56fb-5blx4               3m           40Mi            
cert-manager         cert-manager-webhook-7d6d4c78bc-k58l8                  3m           14Mi            
default              inlets-operator-65d855b646-d7hrb                       1m           14Mi            
istio-system         istio-ingressgateway-5bcdc9b77f-knrpz                  12m          41Mi            
istio-system         istio-ingressgateway-tunnel-client-8676784869-wcbdc    1m           6Mi             
istio-system         istiod-865fd47fcc-24vdp                                4m           48Mi            
kube-system          coredns-f9fd979d6-8mr5v                                4m           11Mi            
kube-system          coredns-f9fd979d6-gbmjz                                5m           11Mi            
kube-system          etcd-openfaas-istio-control-plane                      32m          66Mi            
kube-system          kindnet-mjntd                                          1m           9Mi             
kube-system          kube-apiserver-openfaas-istio-control-plane            83m          412Mi           
kube-system          kube-controller-manager-openfaas-istio-control-plane   19m          52Mi            
kube-system          kube-proxy-jfgtc                                       1m           17Mi            
kube-system          kube-scheduler-openfaas-istio-control-plane            4m           18Mi            
kube-system          metrics-server-56c4ff648b-jzkrq                        2m           15Mi            
local-path-storage   local-path-provisioner-78776bfc44-tgr64                2m           8Mi             
openfaas             alertmanager-7cb8f6487d-ch4fp                          9m           53Mi            
openfaas             basic-auth-plugin-565b7cbc48-h9t8d                     10m          51Mi            
openfaas             gateway-5fb6bf58dd-74j8c                               15m          65Mi            
openfaas             nats-76b689f8d8-mkwtl                                  10m          51Mi            
openfaas             prometheus-5664d7cbb9-kchff                            20m          101Mi           
openfaas             queue-worker-5b7c5b898d-fqkv5                          7m           47Mi            
openfaas-fn          nodeinfo-857d9c469b-ww66k                              12m          63Mi 
```

### Getting a TLS certificate

Let’s now get a TLS certificate so that we can serve traffic to clients securely.

First, create a DNS A record for the IP address of the Istio Ingress gateway using your preferred cloud dashboard and DNS service.

```
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

export INGRESS_HOST=$(minikube ip)

export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo "$GATEWAY_URL"

export GATEWAY_SECURE_URL=$INGRESS_HOST:$SECURE_INGRESS_PORT

echo "$GATEWAY_SECURE_URL"
```

```
kubectl get svc -n istio-system istio-ingressgateway
NAME                   TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   10.98.11.20   10.98.11.20   15021:31113/TCP,80:31305/TCP,443:30666/TCP,31400:30933/TCP,15443:30479/TCP   14h
```

If you’re running within a private VPC, on-premises or on your laptop, then you will need to get a public IP for Istio through the inlets-operator. See a full guide to setting up the inlets-operator with Istio to provide an IP via a secure tunnel. That will then change <pending> to a fully accessible IP.

Otherwise, copy the IP or CNAME issued to you under **EXTERNAL-IP** and create your DNS entry. I’ll be using the domain faas.o6s.io.

| Get minikube ip

```
export OPENFAAS_URL=$(minikube ip):31112
```

**cert-manager is a CNCF project for obtaining, renewing and managing TLS certificates**

You can get a TLS certificate to serve traffic over HTTPS using cert-manager.

```
arkade install cert-manager
```
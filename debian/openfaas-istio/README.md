
# Openfaas with Istio


## Prepare Microk8s Cluster

1. Install microk8s

```bash
sudo snap install microk8s --classic --channel=1.21
```

2. Join the Group

```
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
```

You will also need to re-enter the session for the group update to take place:

```
su - $USER
```

3. Check Status
```
microk8s status --wait-ready
```

4. Enable Ingress & Metallb

```
microk8s enable dns storage metrics-server ingress && \
microk8s enable portainer
```
Enable the Range IP: **main node ip** for metallb
```
microk8s enable metallb
```

Open portainer as NodePort, http://[NODE IP]:30777


## Enable Istio

1. Download Istioctl

```
curl -L https://istio.io/downloadIstio | sh -

cd istio-1.13.0

sudo cp bin/istioctl /usr/local/bin/
```

2. Deploy istio

```
istioctl install --set profile=demo -y
```
Add a namespace label to instruct Istio to automatically inject Envoy sidecar proxies when you deploy your application later
```
kubectl label namespace default istio-injection=enabled
```
Deploy Sample app
```
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```
Associate this application with the Istio gateway:
```
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```
Set the ingress IP and ports:
```
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')

export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo "$GATEWAY_URL"
```
Verify the test page
```
curl "http://$GATEWAY_URL/productpage"
```

Install kiali,jaeger,grafana,prometheus addons
```
kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system

```

## Enable Openfaas

Install Arkade cli
```
# Note: you can also run without `sudo` and move the binary yourself
curl -sLS https://get.arkade.dev | sudo sh

arkade --help
ark --help  # a handy alias

# Windows users with Git Bash
curl -sLS https://get.arkade.dev | sh
```sh
Install Openfaas
```sh
arkade install openfaas \
  --set gateway.directFunctions=true \
  --set istio.mtls=true
```

Install faas-cli
```
curl -sSL https://cli.openfaas.com | sudo -E sh
```

## Enable Istio Gateway for Openfaas

```sh
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

```sh
kubectl port-forward -n istio-system \
  svc/istio-ingressgateway \
  8080:80 \
  8443:443 &
```

Log in:
```sh
PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo)
echo -n $PASSWORD | faas-cli login --username admin --password-stdin
```

Deploy a test function
```sh
# Find something you are interested in with:
faas-cli store list

# Deploy one of the functions
faas-cli store deploy nodeinfo

# Invoke the function
echo | faas-cli invoke nodeinfo
```

You can detect the presence of Envoy within your function by looking at the HTTP headers passed on:

```sh
faas-cli deploy \
  --name env \
  --image ghcr.io/openfaas/alpine:latest \
  --fprocess="env"

echo | faas-cli invoke env
```

## Enable TLS

Install cert-manager
```sh
arkade install cert-manager
```
Now create an Issuer and register it with Let’s Encrypt:
```sh
export EMAIL="afandy@o6s.io"

cat > issuer.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: istio-system
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - selector: {}
      http01:
        ingress:
          class: istio
EOF
kubectl apply -f issuer.yaml
```

Define a certificate:
```sh
export DOMAIN="faas.o6s.io"

cat > cert.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ingress-cert
  namespace: istio-system
spec:
  secretName: ingress-cert
  commonName: $DOMAIN
  dnsNames:
  - $DOMAIN
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
EOF
kubectl apply -f cert.yaml
```

You can then check the status of the issuer and certificate:
```sh
kubectl get clusterissuer,certificate -n istio-system -o wide
```

Modify gateway.yaml
```sh
vim gateway.yaml

--------------------
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
    - faas.o6s.io
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: ingress-cert
    hosts:
    - faas.o6s.io
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
:wq
-----


kubectl apply -f gateway.yaml
```

At this point you can log into OpenFaaS via its public URL and access the nodeinfo function:

```sh
export OPENFAAS_URL="https://faas.o6s.io"
echo -n $PASSWORD | faas-cli login --username admin --password-stdin

Calling the OpenFaaS server to validate the credentials...

credentials saved for admin https://faas.o6s.io
```

Invoke the function:
```sh
curl -s -d "" $OPENFAAS_URL/function/nodeinfo
```
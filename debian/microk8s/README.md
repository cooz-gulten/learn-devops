# Microk8s

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


# Install Helm

Helm: Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.
Let's Begin deploying traefik using helm in traefik , if you are new to helm then download and initialize helm as follows

```bash
wget https://get.helm.sh/helm-v3.0.2-linux-amd64.tar.gz
```

```bash
tar -zxvf helm-v3.0.2-linux-amd64.tar.gz
```

```
cp linux-amd64/helm /usr/bin/
```
```
helm completion bash
```
Can be sourced as such

```
source <(helm completion bash)
```

```
helm repo add default https://kubernetes-charts.storage.googleapis.com/
```
```
"default" has been added to your repositories
```

```
helm repo update
```
```
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "default" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

```
helm search repo traefik
```

```bash
NAME           	CHART VERSION	APP VERSION	DESCRIPTION
default/traefik	1.85.0       	1.7.20     	A Traefik based Kubernetes ingress controller w...
```

```
helm install traefik default/traefik \
--set dashboard.enabled=true,serviceType=NodePort,dashboard.domain=dashboard.traefik,rbac.enabled=true \
--namespace kube-system
```

```
NAME: traefik
LAST DEPLOYED: Sat Jan 11 21:55:37 2020
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Traefik has been started. You can find out the port numbers being used by traefik by running:

          $ kubectl describe svc traefik --namespace kube-system

2. Configure DNS records corresponding to Kubernetes ingress resources to point to the NODE_IP/NODE_HOST
```


View the cluster role

```
kubectl describe clusterrole traefik
```
```
Name:         traefik
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources                    Non-Resource URLs  Resource Names  Verbs
  ---------                    -----------------  --------------  -----
  endpoints                    []                 []              [get list watch]
  pods                         []                 []              [get list watch]
  secrets                      []                 []              [get list watch]
  services                     []                 []              [get list watch]
  ingresses.extensions         []                 []              [get list watch]
  ingresses.extensions/status  []                 []              [update]
```

Check the traefik pods are running in the kube-system namespace

```
kubectl get pods  -n kube-system | grep traefik
```
```
traefik-c689c9f98-vdc88                    1/1     Running   0          27s
```

Traefik has been started. You can find out the port numbers being used by traefik by running:

```
kubectl describe svc traefik --namespace kube-system
```

```
Name:                     traefik
Namespace:                kube-system
Labels:                   app=traefik
                          chart=traefik-1.85.0
                          heritage=Helm
                          release=traefik
Annotations:              <none>
Selector:                 app=traefik,release=traefik
Type:                     NodePort
IP:                       10.96.5.144
Port:                     http  80/TCP
TargetPort:               http/TCP
NodePort:                 http  32650/TCP
Endpoints:                192.168.39.204:80
Port:                     https  443/TCP
TargetPort:               httpn/TCP
NodePort:                 https  32458/TCP
Endpoints:                192.168.39.204:8880
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

View the helm chart deployment

```
helm list -n kube-system
```
```
NAME   	NAMESPACE  	REVISION	UPDATED                             	STATUS  	CHART         	APP VERSION
traefik	kube-system	1       	2020-01-11 21:55:37.295312 +0100 CET	deployed	traefik-1.85.0	1.7.20
```



File: /home/student/deploy-phippy.yaml

```yaml
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: phippy
  labels:
    app: animals
    animal: phippy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: animals
      animal: phippy
  template:
    metadata:
      labels:
        app: animals
        animal: phippy
        version: v0.0.1
    spec:
      containers:
      - name: phippy
        image: hermedia/whoami:phippy
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: phippy
spec:
  ports:
  - name: http
    targetPort: 80
    port: 80
  selector:
    app: animals
    animal: phippy
```

File: /home/student/deploy-captainkube.yaml

```yaml
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: captainkube
  labels:
    app: animals
    animal: captainkube
spec:
  replicas: 2
  selector:
    matchLabels:
      app: animals
      animal: captainkube
  template:
    metadata:
      labels:
        app: animals
        animal: captainkube
        version: v0.0.1
    spec:
      containers:
      - name: moose
        image: hermedia/whoami:captainkube
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: captainkube
spec:
  ports:
  - name: http
    targetPort: 80
    port: 80
  selector:
    app: animals
    animal: captainkube
```

```
kubectl apply -f deploy-phippy.yaml
```

```
deployment.apps/phippy created
service/phippy created
```

```
kubectl apply -f deploy-captainkube.yaml
```

```
deployment.apps/captainkube created
service/captainkube created
```

File: /home/student/ingress-animals.yaml

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: animals
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: phippy.local
    http:
      paths:
      - path: /
        backend:
          serviceName: phippy
          servicePort: http
  - host: captainkube.local
    http:
      paths:
      - path: /
        backend:
          serviceName: captainkube
          servicePort: http
  - host: zee.local
    http:
      paths:
      - path: /zee
        backend:
          serviceName: phippy
          servicePort: http
```

```
kubectl apply -f ingress-animals.yaml
```

```
ingress.networking.k8s.io/animals created
```

```
curl --header 'Host: phippy.local' 10.10.99.101:32650
```
```
<html><head><title>Phippy</title></head><body>
<table style="width:100%"><tr><th>
<img src='images/phippy.png' /></th><th>
<br />Hostname: phippy-56d6b44cd7-57hc2 <br />
<p>IP: 127.0.0.1 </p>
<p>IP: 192.168.69.207 </p>
<p>RemoteAddr: 192.168.39.204:50738 </p></th></tr></table>
</body></html>
```

```
curl --header 'Host: captainkube.local' 10.10.99.101:32650
```
```
<html><head><title>Captain Kube</title></head><body>
<table style="width:100%"><tr><th>
<img src='images/captain-kube.png' /></th><th>
<br />Hostname: captainkube-d8c56d546-jsblf <br />
<p>IP: 127.0.0.1 </p>
<p>IP: 192.168.39.206 </p>
<p>RemoteAddr: 192.168.39.204:49478 </p></th></tr></table>
</body></html>
```

```
curl --header 'Host: zee.local'  10.10.99.101:32650/zee
```
```
<html><head><title>Zee</title></head><body>
<table style="width:100%"><tr><th>
<img src='images/zee.png' /></th><th>
<br />Hostname: phippy-56d6b44cd7-57hc2 <br />
<p>IP: 127.0.0.1 </p>
<p>IP: 192.168.69.207 </p>
<p>RemoteAddr: 192.168.39.204:50738 </p></th></tr></table>
</body></html>
```


# Advanced Service Exposure

## Configure an Ingress Controller

With such a fast changing project, it is important to keep track of updates. The main place to find documentation of the current version is [https://kubernetes.io/](https://kubernetes.io/).



If you have a large number of services to expose outside of the cluster, or to expose a low-number port on the host node you can deploy an ingress controller or a service mesh. While nginx and GCE have controllers officially supported by Kubernetes.io, the Traefik ingress controller is easier to install. At the moment.


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim app1.yaml
```

```yaml
apiVersion: v1  
kind: ReplicationController  
metadata:  
  name: container-ingress-a  
spec:  
  replicas: 1  
  template:  
    metadata:  
      labels:  
        app: container-ingress-a  
    spec:  
      containers:  
        - name: sayhello  
          image: jonbaier/httpwhalesay:0.2  
          command: ["node",  "index.js",  "Container1"]  
          ports:  
          - containerPort: 80
```


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim app2.yaml
```

```yaml
apiVersion: v1  
kind: ReplicationController  
metadata:  
  name: container-ingress-b  
spec:  
  replicas: 1  
  template:  
    metadata:  
      labels:  
        app: container-ingress-b  
    spec:  
      containers:  
        - name: sayhello  
          image: jonbaier/httpwhalesay:0.2  
          command: ["node",  "index.js",  "Container2"]  
          ports:  
          - containerPort: 80
```


```bash
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get replicationcontrollers  
NAME DESIRED CURRENT READY AGE  
container-ingress-a 1 1 1 116m  
container-ingress-b 1 1 1 115m
```

```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl apply -f app1.yaml  
replicationcontroller/container-ingress-a created
```

```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl apply -f app2.yaml  
replicationcontroller/container-ingress-b created
```





Find the labels currently in use by the deployment. We will use them to tie traffic from the ingress controller to the proper service.


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get replicationcontrollers container-ingress-a -o yaml | grep labels -A2  

    labels:  
      app: container-ingress-a  
    name: container-ingress-a  
--  
        labels:  
          app: container-ingress-a  
--  
    labels:  
      app: container-ingress-b  
    name: container-ingress-b  
--  
        labels:  
          app: container-ingress-b  
      spec:
```


Expose the new server as a NodePort.


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim svc-app1.yaml
```


File: svc-app1.yaml


```yaml
apiVersion: v1  
kind: Service  
metadata:  
  name: container-svc-a  
  labels:  
    app: container-ingress-a  
spec:  
  type: NodePort  
  ports:  
  - port: 80  
    nodePort: 31000  
    protocol: TCP  
    name: http  
  selector:  
    app: container-ingress-a
```

```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim svc-app2.yaml
```


File: svc-app2.yaml


```yaml
apiVersion: v1  
kind: Service  
metadata:  
  name: container-svc-b  
  labels:  
    app: container-ingress-b  
spec:  
  type: NodePort  
  ports:  
  - port: 80  
    nodePort: 32000  
    protocol: TCP  
    name: http  
  selector:  
    app: container-ingress-b
```

```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl apply -f svc-app1.yaml  
service/container-svc-a created
```

```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl apply -f svc-app2.yaml  
service/container-svc-b created
```

```bash
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get services  
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE  
container-svc-a NodePort 10.110.187.236 <none> 80:31000/TCP 90s  
container-svc-b NodePort 10.109.209.244 <none> 80:32000/TCP 34s
```
As we have RBAC configured we need to make sure the controller will run and be able to work with all necessary ports, endpoints and resources. Create a YAML file to declare a clusterrole and a clusterrolebinding.


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim ingress.rbac.yaml
```


ingress.rbac.yaml
```yaml
kind: ClusterRole  
apiVersion: rbac.authorization.k8s.io/v1beta1  
metadata:  
  name: traefik-ingress-controller  
rules:  
  - apiGroups:  
      - ""  
    resources:  
      -  services  
      -  endpoints  
      -  secrets  
    verbs:  
      -  get  
      -  list  
      -  watch  
  - apiGroups:  
      -  extensions  
    resources:  
      -  ingresses  
    verbs:  
      -  get  
      -  list  
      -  watch  
---  
kind: ClusterRoleBinding  
apiVersion: rbac.authorization.k8s.io/v1beta1  
metadata:  
  name: traefik-ingress-controller  
roleRef:  
  apiGroup: rbac.authorization.k8s.io  
  kind: ClusterRole  
  name: traefik-ingress-controller  
subjects:  
- kind: ServiceAccount  
  name: traefik-ingress-controller  
  namespace: kube-system  
```



Create the new role and binding.


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f ingress.rbac.yaml  
clusterrole.rbac.authorization.k8s.io/traefik-ingress-controller created  
clusterrolebinding.rbac.authorization.k8s.io/traefik-ingress-controller created
```


Create the Traefik controller. We will use a script directly from their website. This URL has a shorter version below:



https://raw.githubusercontent.com/containous/traefik/master/\examples/k8s/traefik-ds.yaml


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ wget https://tinyurl.com/yawpexdt -O traefik-ds.yaml  
<output_omitted>  
2019-01-24 17:50:44 (188 MB/s) - `traefik-ds.yaml' saved [1206/1206]
```


We need to take out some security context settings, such that the diff output between the new and old would be true.

Add the hostNetwork line and remove the securityContext lines. The indentation for hostNetwork should line up with the containers: line.


```
student@lfs458-node-1a0a:~$ vim traefik-ds.yaml  
#So that diff traefik-ds.yaml.1 ds/traefik-ds.yaml reports this:  
```
```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ cp traefik-ds.yaml traefik-ds.orig.yaml  
```
```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim traefik-ds.yaml
```


File: traefik-ds.yaml


```yaml
....  
    spec:  
      serviceAccountName: traefik-ingress-controller  
      terminationGracePeriodSeconds: 60  
      hostNetwork: true  #<<<---- Add this line  
      containers:  
      - image: traefik  
....  
        securityContext:  #<<<---- Delete this 6 lines  
          capabilities:  
            drop:  
            -  ALL  
            add:  
            -  NET_BIND_SERVICE  
....
```


So that diff traefik-ds.yaml and ds/traefik-ds.orig.yaml reports this:


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ diff traefik-ds.yaml traefik-ds.orig.yaml  
24d23  
<      hostNetwork: true  
34a34,39  
>        securityContext:  
>          capabilities:  
>            drop:  
>            - ALL  
>            add:  
>            - NET_BIND_SERVICE
```


Then create the ingress controller using kubectl create.


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f traefik-ds.yaml  
serviceaccount/traefik-ingress-controller created  
daemonset.extensions/traefik-ingress-controller created  
service/traefik-ingress-service created
```


Now that there is a new controller we need to pass some rules, so it knows how to handle requests. Note that the host mentioned is [www.container-a.local](http://www.container-a.local) and www.container-b.local, which is probably not your node name. We will pass a false header when testing. Also the service name needs to match the containter-a or container-b label we found in an earlier step.


```
student@lfs458-node-1a0a:~$ vim ingress.rule.yaml
```


ingress.rule.yaml


```yaml
apiVersion: extensions/v1beta1  
kind: Ingress  
metadata:  
  name: ingress-test  
  annotations:  
    kubernetes.io/ingress.class: traefik  
spec:  
  rules:  
  - host: www.container-a.local  
    http:  
      paths:  
      - backend:  
          serviceName: container-svc-a  
          servicePort: 80  
        path: /  
  - host: www.container-b.local  
    http:  
      paths:  
        - path: /  
          backend:  
            serviceName: container-svc-b  
            servicePort: 80
```


Now ingest the rule into the cluster.


```
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f container-ingress.yaml  
ingress.extensions/ingress-test created
```


We should be able to test the internal and external IP addresses, and see the whale page. The loadbalancer would present the traffic, a curl request in this case, to the externally facing interface. Use ip a to find the IP address of the interface which would face the loadbalancer. In this example the interface would be ens4, and the IP would be

10.128.0.7.



```html
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ curl -H "Host: www.container-a.local" http://34.252.185.233  
<html>  
    <head>  
        <title>HTTP Whalesay</title>
```
```html
[centos@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ curl -H "Host: www.container-a.local" http://10.10.8.87  
<html>  
    <head>  
        <title>HTTP Whalesay</title>  
    </head>
```


[Back](lab10.md)

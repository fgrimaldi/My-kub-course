# Basic Kubernetes Routing Models

By the end of this exercise, you should be able to:

- Route traffic to a kube deployment using the correct tool in each of the following scenarios:
 - Cluster-internal traffic to a stateless deployment
 - Cluster-internal traffic to a stateful deployment
- Ingress traffic to a stateless deployment
- Establish a network policy to block traffic to or from a pod
- Route requests between pods across Kubernetes namespaces

## Service Types

Kubernetes supports different types of services for different use cases:

- A ClusterIP service makes it accessible from any of the Kubernetes cluster’s nodes. The use of virtual IP addresses for this purpose makes it possible to have several pods expose the same port on the same node – All of these pods will be accessible via a unique IP address.
- For a NodePort service, Kubernetes allocates a port from a configured range (default is 30000-32767), and each node forwards that port, which is the same on each node, to the service. It is possible to define a specific port number, but you should take care to avoid potential port conflicts.
- For a  LoadBalancer service, Kubernetes provisions an external load balancer. The  type of service depends on how the specific Kubernetes cluster is configured.
- An ExternalIP service uses an IP address from the predefined pool of external IP addresses routed to the cluster’s nodes. These external IP addresses are not managed by Kubernetes; they  are the responsibility of the cluster administrator.
- It is also possible to create and use services without selectors. A user can manually map the service to specific endpoints, and  the  service works as if it had a selector. The traffic is routed to endpoints defined by the user
- ExternalName is a special case of service that does not have selectors. It does not define any ports or endpoints. Instead, it returns the name of an external service that resides outside the cluster. Such a service works in the same way as others, with the only difference being that the redirection happens at the DNS level without proxying or forwarding. Later, you may decide to replace an external service with an internal one. In this case, you will need to replace a service definition in your application.


## Service Discovery
Kubernetes supports two modes of finding a service: through environment variables and DNS.

### Environment Variables

Kubernetes injects a set of environment variables into pods for each active service. The order is important: the service should be created before, for example, the replication controller or replica set creates a pod’s replicas. Such environment variables contain service host and port, for example:

```
MYSQL_SERVICE_HOST=10.0.150.150
MYSQL_SERVICE_PORT=3306
```

An application in the pod can use these variables to establish a connection to the service.

### DNS

Kubernetes automatically assigns DNS names to services. A special DNS record can be used to specify port numbers as well. To use DNS for service discovery, a Kubernetes cluster should be properly configured to support it.

## Routing Cluster-Internal Traffic

By *cluster-internal traffic*, we mean traffic from originating from a pod running on your cluster, sending a request to another pod running on the same cluster. We need to consider two cases:

- **Stateless deployments**: can be load balanced across freely. A containerized API would be a common example.
- **Stateful deployments**: we may need to make explicit and consistent decisions about what container we send a request to. A containerized database using simple local storage is a common example.


Services (also called microservices) are objects which declare a policy to access a logical set of Pods. They are typically assigned with labels to allow persistent access to a resource, when front or back end containers are terminated and replaced.

Native applications can use the Endpoints API for access. Non-native applications can use a Virtual IP-based bridge to access back end pods. ServiceTypes Type could be:

- ClusterIP default - exposes on a cluster-internal IP. Only reachable within cluster
- NodePort Exposes node IP at a static port. A ClusterIP is also automatically created.
- LoadBalancer Exposes service externally using cloud providers load balancer. NodePort and ClusterIP automatically created.
- ExternalName Maps service to contents of externalName using a CNAME record.

 We use services as part of decoupling such that any agent or object can be replaced without interruption to access from client to back end application.

### Routing to Stateless Deployments

Routing to stateless deployments internal to a cluster relies on use of a ClusterIP service, which will provide a stable networking endpoint for a collection of containers.

Create a deployment file as follow:

File: /home/student/deploy-destination.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: destination
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: destination  
  template:
    metadata:
      labels:
        app: destination
    spec:
      containers:
      - name: destination-container
        image: containous/whoami
```

2.  Declare a ClusterIP service to route traffic to your `destination` deployment internally:

Create an service file:

File: /home/student/svc-destination.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-destination
  namespace: default
spec:
  selector:
    app: destination
  ports:
  - port: 8080
    targetPort: 80
```

This service will route traffic sent to port 8080 on the IP generated by this service, to port 80 in pods which match the `app: dest` label selector.

3.  Declare another deployment we'll use to send traffic to the first:

copy *deploy-destination.yaml* to *deploy-origin.yaml*

File: /home/student/deploy-origin.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: origin
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: origin
  template:
    metadata:
      labels:
        app: origin
    spec:
      containers:
      - name: origin-container
        image: nicolaka/netshoot:latest
        command: ["sleep"]
        args: ["1000000"]
```

4. Now apply deploy-destination.yaml

```
student@master:~$ kubectl apply -f deploy-destination.yaml
```
```
deployment.apps/destination created
```

Now apply deploy-origin.yaml

```
student@master:~$ kubectl apply -f deploy-origin.yaml
```
```
deployment.apps/origin created
```

Now apply svc-destination.yaml

```
student@master:~$ kubectl apply -f svc-destination.yaml
```
```
service/svc-destination created
```

5.  Run *kubectl exec* inside the container of the deployment *origin*:

```
student@master:~$ kubectl get pod
```
```
NAME                           READY   STATUS    RESTARTS   AGE
destination-6f66576498-h4n7x   1/1     Running   0          2m32s
destination-6f66576498-j84m4   1/1     Running   0          2m32s
destination-6f66576498-xc9kh   1/1     Running   0          2m32s
origin-5b945ff9c5-ncx9r        1/1     Running   0          2m10s
```

```
student@master:~$ kubectl exec -it origin-5b945ff9c5-ncx9r -- /bin/bash      
```
```
bash-5.0#
```

At the terminal, use `nslookup` to see what `svc-destination` resolves as:

```
bash-5.0# nslookup svc-destination
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   svc-destination.default.svc.cluster.local
Address: 10.100.76.46                           
```

The `Address` on the last line is the cluster IP chosen for this service. Traffic to port 8080 (which we defined in the yaml for our service above) at this IP will get randomly load balanced across pods matching the label selector provided.

6.  In the same terminal, try `curl`ing the service name and port:

```
bash-5.0# curl svc-destination:8080
Hostname: destination-6f66576498-j84m4
IP: 127.0.0.1
IP: 192.168.171.102
GET / HTTP/1.1
Host: svc-destination:8080
User-Agent: curl/7.65.1
Accept: */*

bash-5.0# curl svc-destination:8080
Hostname: destination-6f66576498-h4n7x
IP: 127.0.0.1
IP: 192.168.171.103
GET / HTTP/1.1
Host: svc-destination:8080
User-Agent: curl/7.65.1
Accept: */*

bash-5.0# curl svc-destination:8080
Hostname: destination-6f66576498-h4n7x
IP: 127.0.0.1
IP: 192.168.171.103
GET / HTTP/1.1
Host: svc-destination:8080
User-Agent: curl/7.65.1
Accept: */*

bash-5.0# curl svc-destination:8080
Hostname: destination-6f66576498-h4n7x
IP: 127.0.0.1
IP: 192.168.171.103
GET / HTTP/1.1
Host: svc-destination:8080
User-Agent: curl/7.65.1
Accept: */*

bash-5.0# exit
exit
```

Kube ClusterIP services route traffic randomly to pods it serves.

7.  Delete your `svc-destination` service:

```
student@master:~$ kubectl delete -f svc-destination.yaml
```
```
service "svc-destination" deleted
```
[Back](lab05.md)

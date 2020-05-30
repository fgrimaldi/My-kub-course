## Routing Ingress Traffic

In the case that we want to allow traffic in to a deployment from the outside world, we need to route traffic from a port in the host's network namespace onto a port in the pod's network namespace; we can accomplish this through a NodePort service.

### Ingress Traffic to Stateless deployments

In the case of stateless deployments, we want to build off of the ClusterIP service that we saw in the first section above. To do so, we'll create a NodePort service which will forward traffic from a random port on every host in our cluster to a ClusterIP service it automatically creates for us.

1.  Re-create your `svc-nodeport-destination` service as a NodePort service:

File: /home/student/svc-nodeport-destination.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-nodeport-destination
  namespace: default
spec:
  type: NodePort
  selector:
    app: destination
  ports:
  - port: 8080
    targetPort: 80
```

Key values here being the `type: NodePort` to declare this as the desired service type, and the `port` and `targetPort` keys which have the same meaning as the ClusterIP service we created in the first exercise above.

```
student@master:~$ kubectl apply -f svc-nodeport-destination.yaml
```
```
service/svc-nodeport-destination created
```

2.  Find the services and look the *TYPE*,*CLUSTER-IP*,and *PORT(S)* (should be something in the 32768-35535 range).

This is the port your deployment pods are reachable at, on any IP in your kube cluster.

```
student@master:~$ kubectl get svc svc-nodeport-destination
```
```
NAME                       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
svc-nodeport-destination   NodePort   10.99.112.146   <none>        8080:31202/TCP   101s
```

Open your browser using <ip_manager>:<node port> from your `windows` node to confirm the traffic is routed as expected.

You should see something like this:

```
Hostname: destination-6f66576498-j84m4
IP: 127.0.0.1
IP: 192.168.171.102
GET / HTTP/1.1
Host: 10.10.98.10:31202
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3
Accept-Encoding: gzip, deflate
Accept-Language: en-US,en;q=0.9,it;q=0.8
Connection: keep-alive
Dnt: 1
Upgrade-Insecure-Requests: 1
```

3.  Delete your `svc-nodeport-destination` services as above.

```
student@master:~$ kubectl delete svc svc-nodeport-destination
```
```
service "svc-nodeport-destination" deleted
```

Delete your `destination` deployment.

```
student@master:~$ kubectl delete deploy destination
```
```
deployment.extensions "destination" deleted
```

Delete your `origin` deployment.
```
student@master:~$ kubectl delete deploy origin
```
```
deployment.extensions "origin" deleted
```
[Back](lab05.md)

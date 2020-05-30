### Routing to Stateful Deployments


kubectl expose deployment nginx --name nginxheadless --cluster-ip=None
service/nginxheadless exposed



If our destination deployment is stateful, the random load balancing provided by the ClusterIP service above isn't appropriate; we want to be able to discover the IPs of the pods underlying a deployment directly, and make our own routing decisions from there.

1.  Create a new `svc-headless-destination` service, this time as a *headless ClusterIP*:

File:/home/student/svc-headless-destination.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-headless-destination
  namespace: default
spec:
  clusterIP: None
  ports:
  - port: 8080
  selector:
    app: destination
```

```
student@master:~$ kubectl apply -f svc-headless-destination.yaml
```
```
service/svc-headless-destination created
```

```
student@master:~$ kubectl get svc
```
```
NAME                       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
kubernetes                 ClusterIP   10.96.0.1    <none>        443/TCP    4d
svc-headless-destination   ClusterIP   None         <none>        8080/TCP   4s
```

Note the `clusterIP: None` line - that's what makes this service headless. Also, understand that the `port: 8080` key here has no effect for headless services, but is required for API validation; this has been [patched upstream](https://github.com/kubernetes/kubernetes/pull/62497) and won't be required in later versions of Kubernetes.

2.  Open a bash terminal inside the `netshoot` container of our `origin` pod, and try `nslookup` on `svc-headless-destination`:



```
student@master:~$ kubectl exec -it origin-5b945ff9c5-ncx9r -- /bin/bash
```
```
bash-5.0#
```

```
bash-5.0# nslookup svc-headless-destination
```
```
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   svc-headless-destination.default.svc.cluster.local
Address: 192.168.171.103
Name:   svc-headless-destination.default.svc.cluster.local
Address: 192.168.219.111
Name:   svc-headless-destination.default.svc.cluster.local
Address: 192.168.171.102
```
This time, the IPs of all the pods matched by your service's label selector are returned. Try `curl`ing a few of these on port 8000 to confirm the routing works.

```
bash-5.0# for i in $(seq 1 4) ; do curl svc-headless-destination; done
```
```
Hostname: destination-6f66576498-h4n7x
IP: 127.0.0.1
IP: 192.168.171.103
GET / HTTP/1.1
Host: svc-headless-destination
User-Agent: curl/7.65.1
Accept: */*

Hostname: destination-6f66576498-j84m4
IP: 127.0.0.1
IP: 192.168.171.102
GET / HTTP/1.1
Host: svc-headless-destination
User-Agent: curl/7.65.1
Accept: */*

Hostname: destination-6f66576498-h4n7x
IP: 127.0.0.1
IP: 192.168.171.103
GET / HTTP/1.1
Host: svc-headless-destination
User-Agent: curl/7.65.1
Accept: */*

Hostname: destination-6f66576498-xc9kh
IP: 127.0.0.1
IP: 192.168.219.111
GET / HTTP/1.1
Host: svc-headless-destination
User-Agent: curl/7.65.1
Accept: */*
```
Exit from container
```
bash-5.0# exit
```
```
exit
```

[Back](lab05.md)

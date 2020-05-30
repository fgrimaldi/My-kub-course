# Liveness Probes

One of the main benefits of using Kubernetes is its ability to manage and maintain containers running in a cluster, offering virtually zero downtime. You create a pod resource, and Kubernetes selects the worker node for it, and then runs the pod’s containers on it. This powerful capability keeps your application’s containers continuously running, it can also auto-scale the system as demand increases, and even self-heal if a pod or container fails.

In this post, we’ll take a look at how you can use Kubernetes built-in liveness and readiness probes to manage and control the health of your applications.

## What Does It Mean to Self-Heal?

When a pod is scheduled to a node, the kubelet on that node runs its containers and keeps them running as long as the pod exists. The kubelet will restart a container if its main process crashes. But if the application inside of the container throws an error which causes it to continuously restart, Kubernetes has the ability to heal it by using the correct diagnostic and then following the pod’s restart policy.

Within containers, the kubelet can react to two kinds of probes:

- Liveness — The kubelet uses these probes as an indicator to restart a container. A liveness probe is used to detect when an application is running and is unable to make progress. When a container gets in this state, the pod’s kubelet can restart the container via its restart policy.

- Readiness — This type of probe is used to detect if a container is ready to accept traffic. You can use this probe to manage which pods are used as backends for load balancing services. If a pod is not ready, it can then be removed from the list of load balancers.


<table>
  <tr>
    <th></th>
    <th>Liveliness</th>
    <th>Readiness</th>
  </tr>
  <tr>
    <td>On failure</td>
    <td>Kill container</td>
    <td>Stop sending traffic to pod</td>
  </tr>
  <tr>
    <td>Check types</td>
    <td>Http,exec,tcpSocket</td>
    <td>Http,exec,tcpSocket</td>
  </tr>
  <tr>
    <td>Declaration example<br>(pod.yaml)</td>
    <td>
<pre lang="yaml">
livenessProbe:
  failureThreshould: 3
  httpGet:
    path: /healthz
    port: 8080
</pre>
</td>
    <td>
<pre lang="yaml">
readinessProbe:
  httpGet:
    path: /status
    port: 8080
</pre>
  </td>
  </tr>
</table>

## Setting up a Liveness Probe

*This exercise adapted from [https://bit.ly/2ReDQNR](https://bit.ly/2ReDQNR) in accordance with [CC-BY-4.0](https://bit.ly/1rMF155)*

1.  Create a file `liveness.yaml` with the following content:

File: /home/student/liveness.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-test
spec:
  containers:
  - name: liveness
    image: busybox:latest
    args: ["/bin/sh", "-c", "touch /tmp/healthy;
        sleep 30; rm -rf /tmp/healthy; sleep 600"]
    livenessProbe:
      exec:
        command: ["cat", "/tmp/healthy"]
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 1
      failureThreshold: 3
```

This pod creates a file `/tmp/healthy` when it starts, waits 30 seconds, and deletes the file. Meanwhile, Kubernetes will run a liveness probe defined by the `livenessProbe` block:

- `exec:command` is the command that will be run inside this container every probe check; in this case, it checks to see if the file `/tmp/healthy` is present. If so, the check passes; if not, the check fails.
- `initialDelaySeconds` tells Kubernetes to wait 5 seconds after container startup before starting the healthcheck intervals
- `periodSeconds` tells Kube to do a healthcheck every 5 seconds
- `timeoutSeconds` tells Kube to consider the check failed if it hangs for more than 1 second
- `failureThreshold` is the number of consecutive failures required before Kubernetes restarts this container

2.  Deploy this pod:

```
student@master:~$ kubectl apply -f liveness.yaml
```
```
pod/liveness-test created
```

3.  Describe your pod with `kubectl describe pod liveness-test`. At first, everything should report healthy, but after 30-35 seconds, liveness probes will begin to fail with the event report:

```
student@master:~$ kubectl describe pod liveness-test
```
```
Events:
  Type     Reason     Age              From                    Message
  ----     ------     ----             ----                    -------
  Normal   Scheduled  48s              default-scheduler       Successfully assigned default/liveness-test to 0-k8s-worker0
  Normal   Pulling    46s              kubelet, 0-k8s-worker0  Pulling image "busybox:latest"
  Normal   Pulled     43s              kubelet, 0-k8s-worker0  Successfully pulled image "busybox:latest"
  Normal   Created    43s              kubelet, 0-k8s-worker0  Created container liveness
  Normal   Started    42s              kubelet, 0-k8s-worker0  Started container liveness
  Warning  Unhealthy  3s (x2 over 8s)  kubelet, 0-k8s-worker0  Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
  Normal   Killing    34s (x2 over 109s)  kubelet, 0-k8s-worker0  Container liveness failed liveness probe, will be restarted
```

Why does it take this amount of time for healthchecks to start failing? About how much time will elapse before the busybox container is restarted?

4.  After three of these failures, the container will be restarted; a record of how many container restarts have transpired is presented in `kubectl`'s pod summary:

```
student@master:~$ kubectl get pods
```
```
NAME            READY   STATUS    RESTARTS   AGE
liveness-test   1/1     Running   3          5m
```

Finally, notice that even as the container restarts, the pod persists; the pause container within the pod is not restarted, and maintains the pod's IP address and shared namespaces so that healthchecks can restart unhealthy containers without rescheduling the whole pod.

4.  Clean up with `kubectl delete -f liveness.yaml`.

```
student@master:~$ kubectl delete -f liveness.yaml
```
```
pod "liveness-test" deleted
```

## Using HTTP and TCP Socket Liveness Probes

In addition to running scripts inside a container that assess health, we can also attempt to get an HTTP response from a container and check it's headers.

1.  Deploy a containerization of nginx defined by the following file, `liveness-http.yaml`:

File: /home/student/liveness-http.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-http
spec:
  containers:
  - name: liveness
    image: nginx:1.9.1
    livenessProbe:
      httpGet:
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 1
      failureThreshold: 3
```

```
student@master:~$ kubectl apply -f liveness-http.yaml
```
```
pod/liveness-http created
```

Note this is nearly identical to the last example, but replaces the `exec` block in the `livenessProbe` with an `httpGet` block, asking Kubernetes to try to make a connection on port 80 *inside the pod's network namespace*. Response codes from 200 to less than 400 count as success; all other responses count as healthcheck failures.

Delete it

```
student@master:~$ kubectl delete -f liveness-http.yaml```
```
```
pod "liveness-http" deleted
```

2.  `kubectl describe` the pod above, and all should be well; delete it, change the `httpGet:port` to anything other than 80 so the connection fails, and deploy again; after a few seconds, the container will begin reporting as unhealthy due to a `connection refused` error.

File: /home/student/liveness-http-error.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-http-error
spec:
  containers:
  - name: liveness
    image: nginx:1.9.1
    livenessProbe:
      httpGet:
        port: 81
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 1
      failureThreshold: 3
```

```
student@master:~$ kubectl apply -f liveness-http-error.yaml
```
```
pod/liveness-http-error created
```

```
student@master:~$ kubectl describe -f liveness-http-error.yaml
```
```
Events:
  Type     Reason     Age                 From                    Message
  ----     ------     ----                ----                    -------
  Normal   Scheduled  110s                default-scheduler       Successfully assigned default/liveness-http-error to 0-k8s-worker0
  Normal   Pulled     48s (x4 over 108s)  kubelet, 0-k8s-worker0  Container image "nginx:1.9.1" already present on machine
  Normal   Created    48s (x4 over 108s)  kubelet, 0-k8s-worker0  Created container liveness
  Normal   Killing    48s (x3 over 88s)   kubelet, 0-k8s-worker0  Container liveness failed liveness probe, will be restarted
  Normal   Started    47s (x4 over 107s)  kubelet, 0-k8s-worker0  Started container liveness
  Warning  Unhealthy  38s (x10 over 98s)  kubelet, 0-k8s-worker0  Liveness probe failed: Get http://192.168.131.212:81/: dial tcp 192.168.131.212:81: connect: connection refused
```

3.  Clean up as usual with `kubectl delete -f liveness-http-error.yaml`.

```
student@master:~$ kubectl delete -f liveness-http-error.yaml
```
```
pod "liveness-http-error" deleted
```

4.  Perform the last three steps again, but in `liveness-http.yaml` replace `httpGet` with `tcpSocket`; now Kubernetes will try to establish a socket connection on the specified port as its healthcheck, with a successful connection passing the check and an unsuccessful connection counting as a healthcheck failure.

File: /home/student/liveness-http-tcpsocket.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-http-tcpsocket
spec:
  containers:
  - name: liveness
    image: nginx:1.9.1
    livenessProbe:
      tcpSocket:
        port: 81
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 1
      failureThreshold: 3
```

```
student@master:~$ kubectl apply -f liveness-http-tcpsocket.yaml
```
```
pod/liveness-http-tcpsocket created
```

```
student@master:~$ kubectl describe -f liveness-http-tcpsocket.yaml
```
```
Events:
  Type     Reason     Age              From                    Message
  ----     ------     ----             ----                    -------
  Normal   Scheduled  20s              default-scheduler       Successfully assigned default/liveness-http-tcpsocket to 0-k8s-worker0
  Normal   Pulled     19s              kubelet, 0-k8s-worker0  Container image "nginx:1.9.1" already present on machine
  Normal   Created    18s              kubelet, 0-k8s-worker0  Created container liveness
  Normal   Started    18s              kubelet, 0-k8s-worker0  Started container liveness
  Warning  Unhealthy  4s (x2 over 9s)  kubelet, 0-k8s-worker0  Liveness probe failed: dial tcp 192.168.131.214:81: connect: connection refused
```

5.  Delete your nginx pod again as above in preparation for future exercises.

```
student@master:~$ kubectl delete -f liveness-http-tcpsocket.yaml
```
```
pod "liveness-http-tcpsocket" deleted
```



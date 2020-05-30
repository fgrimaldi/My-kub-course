## Sidecar Container

Create a Pod with a sidecar container that expose the log file:

```
~# vi sidecar-pod.yml
```


```
apiVersion: v1
kind: Pod
metadata:
  name:sidecar-pod
spec:
  volumes:
  - name: logs-sharing 
    emptyDir: {}
  containers:
  - name: main-app-container
    image: alpine
    command: ["/bin/sh"]
    args: ["-c", "while true; do date >> /var/log/app.txt; sleep 5;done"]
    volumeMounts:
    - name: logs-sharing
      mountPath: /var/log
  - name: sidecar-container
    image: nginx:1.7.9
    ports:
      - containerPort: 80
    volumeMounts:
    - name: logs-sharing
      mountPath: /usr/share/nginx/html
```

Apply the Pod:
```
~# kubectl apply -f sidecar-pod.yml
pod/sidecar-pod created
~# kubectl get pod
NAME          READY   STATUS              RESTARTS   AGE
sidecar-pod   0/2     ContainerCreating   0          7s
:~# kubectl get pod
NAME          READY   STATUS    RESTARTS   AGE
sidecar-pod   2/2     Running   0          28s
```

Connect inside the sidecar container:
```
~# kubectl exec sidecar-pod -c sidecar-container -it bash
root@sidecar-pod:/#
```
Now install curl and access to the log file from the sidecar Container
```
root@sidecar-pod:/# apt-get update && apt-get install curl
<output_omitted>

root@sidecar-pod:/# curl 'http://localhost:80/app.txt'
(date every 5 sec.)
.
.
.
```

## Adapter Container

Create a Pod with an adapter container to reformatting pattern:

```
~# vi adapter-pod.yml
```

```
apiVersion: v1
kind: Pod
metadata:
  name: adapter-pod
spec:
  volumes:
  - name: logs-sharing 
    emptyDir: {}
  containers:
  - name: main-app-container
    # This application writes system usage information (`top`) to a status 
    # file every five seconds.
    image: alpine
    command: ["/bin/sh"]
    args: ["-c", "while true; do date > /var/log/top.txt && top -n 1 -b >> /var/log/top.txt; sleep 5;done"]
    volumeMounts:
    - name: logs-sharing
      mountPath: /var/log
  - name: adapter-container
    # Our adapter container will inspect the contents of the app's top file,
    # reformat it, and write the correctly formatted output to the status file
    image: alpine
    command: ["/bin/sh"]
    args: ["-c", "while true; do (cat /var/log/top.txt | head -1 > /var/log/status.txt) && (cat /var/log/top.txt | head -2 | tail -1 | grep
 -o -E '\\d+\\w' | head -1 >> /var/log/status.txt) && (cat /var/log/top.txt | head -3 | tail -1 | grep
-o -E '\\d+%' | head -1 >> /var/log/status.txt); sleep 5; done"]
    volumeMounts:
    - name: logs-sharing
      mountPath: /var/log
```

Apply the pod: 
```
~# kubectl apply -f adapter-pod.yml
pod/adapter-pod created
~# kubectl get pod
NAME          READY   STATUS              RESTARTS   AGE
adapter-pod   0/2     ContainerCreating   0          6s
~# kubectl get pod
NAME          READY   STATUS    RESTARTS   AGE
adapter-pod   2/2     Running   0          90s
```

Connect inside the main-application container and check the log writing and the logs reformatting:

```
~# kubectl exec adapter-pod -c main-app-container -it sh
/ #
```

Check 'top' output first:
```
/ # cat /var/log/top.txt
Mon Dec 16 16:22:35 UTC 2019
Mem: 2902696K used, 1125800K free, 12952K shrd, 100276K buff, 1820668K cached
CPU:   0% usr   0% sys   0% nic 100% idle   0% io   0% irq   0% sirq
Load average: 0.41 0.30 0.36 1/731 608
  PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
  349   341 root     S     1624   0%   3   0% sh
    1     0 root     S     1616   0%   3   0% /bin/sh -c while true; do date > /var/log/top.txt && top -n 1 -b >> /var/log/top.txt; sleep 5;done
  608     1 root     R     1556   0%   1   0% top -n 1 -b

```
Then the reformatted pattern for a status view :
```
/ # cat /var/log/status.txt
Mon Dec 16 16:20:33 UTC 2019
2902728K
4%
```

[Back](lab02.md)

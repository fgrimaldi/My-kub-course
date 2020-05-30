
# Assign Pods Using Labels

## Overview

While allowing the system to distribute Pods on your behalf is typically the best route, you may want to determine which nodes a Pod will use. For example you may have particular hardware requirements to meet for the workload. You may want to assign AI Pods to special hardware and everyone else to normal hardware.

In this exercise we will use labels to schedule Pods to a particular node. Then we will explore taints to have more flexible deployment in a large environment.

# Assign Pods Using Labels

Begin by getting a list of the nodes. They should be in the ready state and without added labels or taints.


```
student@master:~$ kubectl get nodes
NAME     STATUS   ROLES    AGE     VERSION
master   Ready    master   2d14h   v1.15.0
worker   Ready    <none>   2d12h   v1.15.0
```


View the current labels and taints for the nodes.


```
student@master:~$ kubectl get nodes --show-labels
```
```
master   Ready    master   2d14h   v1.15.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=master,kubernetes.io/os=linux,node-role.kubernetes.io/master=
worker   Ready    <none>   2d12h   v1.15.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker,kubernetes.io/os=linux
```


```
student@master:~$ kubectl describe nodes | grep -i taint
```
```
Taints:             <none>
Taints:             <none>
```

```
student@master:~$ sudo docker ps | wc -l
```
```
20
```

```
student@worker:~$ sudo docker ps | wc -l
```
```
5
```


Verify there are no deployments running, outside of the kube-system namespace. If there are, delete them. Then get a count of how many containers are running on both the master and secondary nodes. There are about 19 containers running on the master in the following example, and five running on the worker. There are status lines which increase the wc count. You may have more or less, depending on previous labs and cleaning up of resources.


```
student@master:~$ kubectl get deployments --all-namespaces
```
```
NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   calico-kube-controllers   1/1     1            1           2d13h
kube-system   coredns                   2/2     2            2           2d14h
```

For the purpose of the exercise we will assign the master node to be special hardware and the secondary node to be normal.


```
student@master:~$ kubectl label nodes worker status=special
```
```
node/worker labeled
```

```
student@master:~$ kubectl label nodes master status=normal
```
```
node/master labeled
```


Verify your settings. You will also find there are some built in labels such as hostname, os and architecture type. The output below appears on multiple lines for readability.



```
student@master:~$ kubectl get nodes --show-labels
```
```
NAME     STATUS   ROLES    AGE     VERSION   LABELS
master   Ready    master   2d14h   v1.15.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=master,kubernetes.io/os=linux,node-role.kubernetes.io/master=,status=normal
worker   Ready    <none>   2d12h   v1.15.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker,kubernetes.io/os=linux,status=special
```

Create deploy-special.yaml to spawn four busybox replicas pods which sleep the whole time. Include the nodeSelector entry.

File: /home/student/deploy-special.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: special
spec:
  replicas: 4
  selector:
    matchLabels:
      app: special
  template:
    metadata:
      labels:
        app: special
    spec:
      containers:
      - name: special01
        image: busybox
        args:
        - sleep
        - "100000000"
      nodeSelector:
        status: special
```

```
student@master:~$ kubectl apply -f deploy-special.yaml
```
```
deployment.apps/special created
```
Check where special deployment are running using *kubectl describe*

```
student@master:~$ kubectl describe pod special | grep Node:
```
```
Node:           worker/10.10.98.11
Node:           worker/10.10.98.11
Node:           worker/10.10.98.11
Node:           worker/10.10.98.11
```
Now count docker containers in master:

```
student@master:~$ sudo docker ps | wc -l
```
```
19
```

Count docker containers in worker:

```
student@worker:~$ sudo docker ps | wc -l
```
```
13
```

In the worker in original was 5 containers. You should add 4 container busybox, 4 container pause. In total 13 containers.

Delete the pod. It may take a while for the containers to fully terminate.

```
student@master:~$ kubectl delete deploy special
```
```
deployment.extensions "special" deleted
```

Copy the file from *deploy-special.yaml* to *deploy-noselector.yaml* the file, commenting out the nodeSelector lines.



File: /home/student/deploy-noselector.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: noselector
spec:
  replicas: 4
  selector:
    matchLabels:
      app: noselector
  template:
    metadata:
      labels:
        app: noselector
    spec:
      containers:
      - name: noselector01
        image: busybox
        args:
        - sleep
        - "100000000"
#      nodeSelector:
#        status: special
```

Create the deployment again. Containers should now be spawning on both nodes.

```
student@master:~$ kubectl get deployment
```
```
No resources found.
```
Deploy the new deployment. Verify the containers have been created on the master node. It may take a few seconds for all the containers to spawn. Check both the master and the secondary nodes.
```
student@master:~$ kubectl apply -f deploy-noselector.yaml
```
```
deployment.apps/noselector created
```

```
student@master:~$ kubectl describe pod noselector | grep Node:
```
```
Node:           worker/10.10.98.11
Node:           master/10.10.98.10
Node:           master/10.10.98.10
Node:           worker/10.10.98.11
```

```
student@master:~$ sudo docker ps | wc -l
```
```
24
```

```
student@worker:~$ sudo docker ps | wc -l
```
```
9
```

```
student@master:~$ kubectl delete deploy noselector
```
```
deployment.extensions "noselector" deleted
```

```
student@master:~$ kubectl get deployment
```
```
No resources found.
```


Copy the file from *deploy-special.yaml* to *deploy-normal.yaml* the file, and change it as follow:

File: /home/student/deploy-normal.yaml
```YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: normal
spec:
  replicas: 4
  selector:
    matchLabels:
      app: normal
  template:
    metadata:
      labels:
        app: normal
    spec:
      containers:
      - name: normal01
        image: busybox
        args:
        - sleep
        - "100000000"
      nodeSelector:
        status: normal
```

Deploy the new deployment. Verify the containers have been created on the master node. It may take a few seconds for all the containers to spawn. Check both the master and the secondary nodes.

```
student@master:~$ kubectl apply -f deploy-normal.yaml
```
```
deployment.apps/normal created
```
Check where special deployment are running using *kubectl describe*
```
student@master:~$ kubectl describe pod normal | grep Node:
```
```
Node:           master/10.10.98.10
Node:           master/10.10.98.10
Node:           master/10.10.98.10
Node:           master/10.10.98.10
```

Delete normal deployment

```
student@master:~$ kubectl delete deploy normal
```
```
deployment.extensions "normal" deleted
```

[Back](lab04.md)

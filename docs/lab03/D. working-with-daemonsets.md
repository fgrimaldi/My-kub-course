# Working with DaemonSets

## Overview

  

A DaemonSet is a watch loop object like a Deployment which we have been working with in the rest of the labs. The DaemonSet ensures that when a node is added to a cluster a pods will be created on that node. A Deployment would only ensure a particular number of pods are created in general, several could be on a single node. Using a DaemonSet can be helpful to ensure applications are on each node, helpful for things like metrics and logging especially in large clusters where hardware may be swapped out often. Should a node be be removed from a cluster the DaemonSet would ensure the Pods are garbage collected before removal. Starting with Kubernetes v1.12 the scheduler handles DaemonSet deployment which means we can now configure certain nodes to not have a particular DaemonSet pods.

  

This extra step of automation can be useful for using with products like ceph where storage is often added or removed, but perhaps among a subset of hardware. They allow for complex deployments when used with declared resources like memory, CPU or volumes.

File: /home/student/ds.yaml

  
```yaml
apiVersion: apps/v1
kind: DaemonSet #<<<---- Change to Daemonset  
metadata:  
  name: daemonset1 #<<<---- Change the name of Daemonset  
spec:
  replicas: 2 #<<<----Remove this line
  template:  
    metadata:  
      labels:  
        system: daemonset1 #<<<---- Change the system label  
    spec:  
      containers:  
      - name: nginx  
        image: nginx:1.7.9  
        ports:  
        - containerPort: 80
```
  

Create and verify the newly formed DaemonSet. There should be one Pod per node in the cluster.

  
```
student@master:~$ kubectl create -f ds.yaml
daemonset.extensions/daemonset1 created
```
  
```bash
student@master:~$ kubectl get ds
NAME DESIRED CURRENT READY UP-TO-DATE AVAILABLE NODE SELECTOR AGE
daemonset1 2 2 2 2 2 <none> 17s
```
  
```bash
student@master:~$ kubectl get po
NAME READY STATUS RESTARTS AGE
daemonset1-kq7pj 1/1 Running 0 42s
daemonset1-plbr7 1/1 Running 0 42s
```
  

Verify the image running inside the Pods. We will use this information in the next section.

  
```
student@master:~$ kubectl describe pod daemonset1-kq7pj | grep Image:
Image: nginx:1.7.9
```

[Back](lab03.md)

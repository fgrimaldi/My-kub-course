
# Creating a Persistent Volume Claim (PVC)

Before Pods can take advantage of the new PV we need to create a Persistent Volume Claim (PVC).

Begin by determining if any currently exist.


```
$ kubectl get pvc
No resources found.
```

Create a YAML file for the new pvc.

File: pvc-1.yaml


```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-1
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```


Create and verify the new pvc is bound. 

<!-- Note that the size is 1Gi, even though 150Mi was suggested. Only a volume of at least that size could be used. -->

```
$ kubectl apply -f pvc-1.yaml
persistentvolumeclaim/pvc-1 created
```

```bash  
$ kubectl get pvc
NAME    STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-1   Bound    pv-nfs   1Gi        RWX                           88s
```

Look at the status of the pv again, to determine if it is in use. It should show a status of Bound.


```bash
$ kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM           STORAGECLASS   REASON   AGE
pv-nfs   1Gi        RWX            Retain           Bound    default/pvc-1                           8m22s
```

Create a new deployment to use the pvc. We will copy and edit an existing deployment yaml file. We will change the deployment name then add a volumeMounts section under containers and volumes section to the general spec. The name used must match in both places, whatever name you use. The claimName must match an existing pvc. As shown in the following example.





File: /home/student/pod-pvc.yaml

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-pvc
  labels:
    app: application01
spec:
  containers:
    - name: busybox
      image: busybox
      command: ['sh', '-c', 'sleep 5 && ls /nfs-mount && sleep 3600']
      volumeMounts: 
      - name: volume-nfs 
        mountPath: /nfs-mount 
  volumes: 
  - name: volume-nfs 
    persistentVolumeClaim: 
      claimName: pvc-1 
```



```
$ kubectl apply -f pod-pvc.yaml
pod/pod-pvc created
```



Look at the details of the pod. You may see the daemonset pods running as well.


```bash
$ kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
pod-pvc   1/1     Running   0          97s
```

```
$ kubectl describe pod pod-pvc
Name:         pod-pvc
Namespace:    default
Priority:     0
. . .
    Mounts:
      /nfs-mount from volume-nfs (rw)
. . . 
Volumes:
  volume-nfs:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  pvc-1
    ReadOnly:   false
<output_omitted>
```

View the status of the PVC. It should show as bound.


```bash
NAME    STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-1   Bound    pv-nfs   1Gi        RWX                           13m
```

Check logs for see list directory of the folder /nfs-mount

```
$ kubectl logs pod-pvc
file.txt
```





[Back](lab07.md)

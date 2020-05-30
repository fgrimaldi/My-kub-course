
https://docs.openshift.com/enterprise/3.2/dev_guide/compute_resources.html
http://gen.lib.rus.ec/search.php?req=kubernetes&lg_topic=libgen&open=0&view=simple&res=25&phrase=1&column=def


# Exercise 9.4: Using a ResourceQuota to Limit PVC Count and Usage



The flexibility of cloud-based storage often requires limiting consumption among users. We will use the ResourceQuota object to both limit the total consumption as well as the number of persistent volume claims.



Begin by deleting the deployment we had created to use NFS, the pv and the pvc.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete deployments nginx-nfs
deployment.extensions "nginx-nfs" deleted
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete pvc persistentvolumeclaim1
persistentvolumeclaim "persistentvolumeclaim1" deleted
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete pv pvnfs-1
persistentvolume "pvnfs-1" deleted
```


Create a yaml file for the ResourceQuota object. Set the storage limit to 5 claims with a total usage of 150Mi.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim resource-quota.yaml
```


storage-quota.yaml


```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: storage-resource-quota
spec:
  hard:
    persistentvolumeclaims: 5
    requests.storage: "150Mi"
```


Create a new namespace called small. View the namespace information prior to the new quota. Either the long name with double dashes --namespace or the nickname ns work for the resource.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create namespace quota-small
namespace/quota-small created
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small
Name: quota-small
Labels: <none>
Annotations: <none>
Status: Active

No resource quota.

No resource limits.
```


Create a new pv and pvc in the small namespace.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f persistentVolNfs.yaml -n quota-small
persistentvolume/pvnfs-1 created
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f persistentVolumeClaim.yaml -n quota-small
persistentvolumeclaim/persistentvolumeclaim1 created
```


Create the new resource quota, placing this object into the quota-small namespace.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f resource-quota.yaml -n quota-small  
resourcequota/storage-resource-quota created
```


Verify the quota-small namespace has quotas. Compare the output to the same command above.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small
Name: quota-small
Labels: <none>
Annotations: <none>
Status: Active

Resource Quotas
 Name: storage-resource-quota
 Resource Used Hard
 -------- --- ---
 persistentvolumeclaims 1 5
 requests.storage 150Mi 150Mi

No resource limits.
```




Remove the namespace line from the nfs-pod.yaml file. Should be around line 11 or so. This will allow us to pass other namespaces on the command line.


```
student@lfs458-node-1a0a:~$ vim nfs-pod.yaml  
```  
Create the container again.  
```
student@lfs458-node-1a0a:~$ kubectl create -f nfs-pod.yaml n  
-n small  
deployment.apps/nginx-nfs created
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim pod-with-nfs.yaml
```


File: pod-with-nfs.yaml


```yaml
apiVersion: extensions/v1beta1  
kind: Deployment  
metadata:  
  annotations:  
    deployment.kubernetes.io/revision:  "1"  
  generation: 1  
  labels:  
    app: nginx  
  name: nginx-nfs  
  namespace: default #<--- delete this line  
spec:
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f pod-with-nfs.yaml -n quota-small  
deployment.extensions/nginx-nfs created
```


Determine if the deployment has a running pod.


```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get deploy --namespace=quota-small
NAME READY UP-TO-DATE AVAILABLE AGE
nginx-nfs 1/1 1 1 57s
```
```  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small describe deploy nginx-nfs  
<output_omitted>
```


Look to see if the pods are ready.


```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get pod -n quota-small
NAME READY STATUS RESTARTS AGE
nginx-nfs-74f68698bc-52msw 1/1 Running 0 2m
```


Ensure the Pod is running and is using the NFS mounted volume. If you pass the namespace first Tab will auto-complete the pod name.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small describe pod nginx-nfs-74f68698bc-52msw
Name: nginx-nfs-74f68698bc-52msw
Namespace: quota-small
....  
    Mounts:
      /nfs-mount from volume-nfs (rw)  
<output_omitted>
```


View the quota usage of the namespace


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small
Name: quota-small
Labels: <none>
Annotations: <none>
Status: Active

Resource Quotas
 Name: storage-resource-quota
 Resource Used Hard
 -------- --- ---
 persistentvolumeclaims 1 5
 requests.storage 150Mi 150Mi

No resource limits.
```


Create a 100M file inside of the /opt/nfs directory on the host and view the quota usage again. Note that with NFS the size of the share is not counted against the deployment.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ sudo dd if=/dev/zero of=/opt/nfs/bigfile bs=1M count=100
100+0 records in
100+0 records out
104857600 bytes (105 MB, 100 MiB) copied, 0.734278 s, 143 MB/s
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small
Name: quota-small
Labels: <none>
Annotations: <none>
Status: Active

Resource Quotas
 Name: storage-resource-quota
 Resource Used Hard
 -------- --- ---
 persistentvolumeclaims 1 5
 requests.storage 150Mi 150Mi

No resource limits.
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ du -h /opt/
101M  /opt/nfs
98M  /opt/cni/bin
98M  /opt/cni
198M  /opt/
```


Now let us illustrate what happens when a deployment requests more than the quota. Begin by shutting down the existing deployment.


```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small get deploy
NAME READY UP-TO-DATE AVAILABLE AGE
nginx-nfs 1/1 1 1 8m7s
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small delete deploy nginx-nfs
deployment.extensions "nginx-nfs" deleted
```


Once the Pod has shut down view the resource usage of the namespace again. Note the storage did not get cleaned up when the pod was shut down.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small
Name: quota-small
Labels: <none>
Annotations: <none>
Status: Active

Resource Quotas
 Name: storage-resource-quota
 Resource Used Hard
 -------- --- ---
 persistentvolumeclaims 1 5
 requests.storage 150Mi 150Mi

No resource limits.
```


Remove the pvc then view the pv it was using. Note the RECLAIM POLICY and STATUS.


```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get persistentvolumeclaims -n quota-small
NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS AGE
persistentvolumeclaim1 Bound pvnfs-1 1Gi RWX 15m
```
```  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small delete pvc persistentvolumeclaim1
persistentvolumeclaim "persistentvolumeclaim1" deleted
```
```bash  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small get pv
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS REASON AGE
pvnfs-1 1Gi RWX Retain Released quota-small/persistentvolumeclaim1 17m
```


Dynamically provisioned storage uses the ReclaimPolicy of the StorageClass which could be Delete, Retain, or some types allow Recycle. Manually created persistent volumes default to Retain unless set otherwise at creation.

The default storage policy is to retain the storage to allow recovery of any data. To change this begin by viewing the yaml output.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get pv/pvnfs-1 -o yaml
....  
  nfs:
    path: /opt/nfs
    server: 192.168.158.130
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
status:
  phase: Released
....
```


Currently we will need to delete and re-create the object. Future development on a deleter plugin is planned. We will re-create the volume and allow it to use the Retain policy, then change it once running.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete pv/pvnfs-1
persistentvolume "pvnfs-1" deleted
```
```  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ grep Retain persistentVolNfs.yaml
persistentVolumeReclaimPolicy: Retain
```
```  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f persistentVolNfs.yaml
persistentvolume/pvnfs-1 created
```


We will use kubectl patch to change the retention policy to Delete. The yaml output from before can be helpful in getting the correct syntax.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl patch pv pvnfs-1 -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
persistentvolume/pvnfs-1 patched
```
```bash  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get pv/pvnfs-1
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS REASON AGE
pvnfs-1 1Gi RWX Delete Available 6m10s
```


View the current quota settings.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small
Name: quota-small
Labels: <none>
Annotations: <none>
Status: Active

Resource Quotas
 Name: storage-resource-quota
 Resource Used Hard
 -------- --- ---
 persistentvolumeclaims 0 5
 requests.storage 0 150Mi

No resource limits.
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small create -f persistentVolumeClaim.yaml  
persistentvolumeclaim/persistentvolumeclaim1 created  
```
```  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small  
Name: quota-small  
Labels: <none>  
Annotations: <none>  
Status: Active  

Resource Quotas  
 Name: storage-resource-quota  
 Resource Used Hard  
 -------- --- ---  
 persistentvolumeclaims 1 5  
 requests.storage 150Mi 150Mi  

No resource limits.
```


Remove the existing quota from the namespace.


```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small get resourcequotas
NAME CREATED AT
storage-resource-quota 2019-02-18T23:02:38Z
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small delete resourcequotas storage-resource-quota
resourcequota "storage-resource-quota" deleted
```


Edit the resource-quota.yaml file and lower the capacity to 50Mi.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim resource-quota.yaml
```


File: resource-quota.yaml


```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: storage-resource-quota
spec:
  hard:
    persistentvolumeclaims: 5
    requests.storage: "50Mi" #<<<---- change this to 50Mi
```


Create and verify the new storage quota. Note the hard limit has already been exceeded.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small create -f resource-quota.yaml
resourcequota/storage-resource-quota created
```
```  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small
Name: quota-small
Labels: <none>
Annotations: <none>
Status: Active

Resource Quotas
 Name: storage-resource-quota
 Resource Used Hard
 -------- --- ---
 persistentvolumeclaims 1 5
 requests.storage 150Mi 50Mi

No resource limits.
```


Create the deployment again. View the deployment. Note there are no errors seen.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f pod-with-nfs.yaml -n quota-small
deployment.extensions/nginx-nfs created
```



```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small describe deploy/nginx-nfs
Name: nginx-nfs
Namespace: quota-small  
<output_omitted>
```


Examine the pods to see if they are actually running.


```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small get pod
NAME READY STATUS RESTARTS AGE
nginx-nfs-74f68698bc-wwgmk 1/1 Running 0 69s
```


As we were able to deploy more pods even with apparent hard quota set, let us test to see if the reclaim of storage takes place. Remove the deployment and the persistent volume claim.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small delete deploy nginx-nfs
deployment.extensions "nginx-nfs" deleted
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small delete pvc persistentvolumeclaim1
persistentvolumeclaim "persistentvolumeclaim1" deleted
```


View if the persistent volume exists. You will see it attempted a removal, but failed. If you look closer you will find the error has to do with the lack of a deleter volume plugin for NFS. Other storage protocols have a plugin.


```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small get pv
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS REASON AGE
pvnfs-1 1Gi RWX Delete Failed quota-small/persistentvolumeclaim1 16m
```


Ensure the deployment, pvc and pv are all removed.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete pv pvnfs-1
persistentvolume "pvnfs-1" deleted
```


Edit the persistent volume YAML file and change the persistentVolumeReclaimPolicy: to Recycle.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim persistentVolNfs.yaml
```


File: persistentVolNfs.yaml


```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pvnfs-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle # <<<---- Change this row
  nfs:
    path: /opt/nfs
    server: 192.168.158.130
    readOnly: false
```


Add a LimitRange to the namespace and attempt to create the persistent volume and persistent volume claim again.

We can use the LimitRange we used earlier.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small create -f ns-with-limit-range.yaml
limitrange/ns-with-limit-range created
```


View the settings for the namespace. Both quotas and resource limits should be seen.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small  
Name: quota-small  
Labels: <none>  
Annotations: <none>  
Status: Active  

Resource Quotas  
 Name: storage-resource-quota  
 Resource Used Hard  
 -------- --- ---  
 persistentvolumeclaims 0 5  
 requests.storage 0 50Mi  

Resource Limits  
 Type Resource Min Max Default Request Default Limit Max Limit/Request Ratio  
 ---- -------- --- --- --------------- ------------- -----------------------  
 Container cpu - - 500m 1 -  
 Container memory - - 100Mi 500Mi -
```



Create the persistent volume again. View the resource. Note the Reclaim Policy is Recycle.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small create -f persistentVolNfs.yaml
persistentvolume/pvnfs-1 created
```
```bash  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get pv
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS REASON AGE
pvnfs-1 1Gi RWX Recycle Available 16s
```


Attempt to create the persistent volume claim again. The quota only takes effect if there is also a resource limit in effect.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small create -f persistentVolumeClaim.yaml
Error from server (Forbidden): error when creating "persistentVolumeClaim.yaml": persistentvolumeclaims "persistentvolumeclaim1" is forbidden: exceeded quota: storage-resource-quota, requested: requests.storage=150Mi, used: requests.storage=0, limited: requests.storage=50Mi
```


Edit the resourcequota to increase the requests.storage to 500mi.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small edit resourcequotas

....  
spec:
  hard:
    persistentvolumeclaims: "5"
    requests.storage: 500Mi #<<<----- Change this row to 500Mi
status:
  hard:
    persistentvolumeclaims: "5"
....

resourcequota/storage-resource-quota edited
```





Create the pvc again. It should work this time. Then create the deployment again.




```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small create -f persistentVolumeClaim.yaml
persistentvolumeclaim/persistentvolumeclaim1 created
```
```  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small create -f pod-with-nfs.yaml
deployment.extensions/nginx-nfs created
```




View the namespace settings.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl describe ns quota-small
<output_omitted>
```


Delete the deployment. View the status of the pv and pvc.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small delete deploy nginx-nfs
deployment.extensions "nginx-nfs" deleted
```

```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small get pvc
NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS AGE
persistentvolumeclaim1 Bound pvnfs-1 1Gi RWX 110s
```

```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small get pv
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS REASON AGE
pvnfs-1 1Gi RWX Recycle Bound quota-small/persistentvolumeclaim1 5m34s
```


Delete the pvc and check the status of the pv. It should show as Available.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small delete pvc persistentvolumeclaim1
persistentvolumeclaim "persistentvolumeclaim1" deleted
```
```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl -n quota-small get pv
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS REASON AGE
pvnfs-1 1Gi RWX Recycle Available 6m20s
```


Remove the pv and any other resources created during this lab.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete pv pvnfs-1
persistentvolume "pvnfs-1" deleted
```


[Back](lab11.md)


# Creating a Persistent NFS Volume (PV)

Return to the master node and create a YAML file for the object with kind, PersistentVolume. Use the hostname of the master server and the directory you created in the previous step. Only syntax is checked, an incorrect name or directory will not generate an error, but a Pod using the resource will not start. Note that the accessModes do not currently affect actual access and are typically used as labels instead.

File: pv-nfs.yaml

```yaml
apiVersion: v1  
kind: PersistentVolume  
metadata:  
  name: pv-nfs  
spec:  
  capacity:  
    storage: 1Gi  
  accessModes:  
    -  ReadWriteMany  
  persistentVolumeReclaimPolicy: Retain  
  nfs:  
    path: /opt/nfs  
    server: 10.10.98.129  #<-- Edit to match master node  
    readOnly: false
```

Create the persistent volume, then verify its creation.

```
$ kubectl  apply -f pv-nfs.yaml
persistentvolume/pv-nfs created
```

```bash
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv-nfs   1Gi        RWX            Retain           Available                                   17s
```

[Back](lab07.md)

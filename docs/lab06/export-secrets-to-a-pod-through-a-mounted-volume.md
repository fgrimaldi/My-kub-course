
# Export Secrets to a pod through a mounted volume.

Secrets may be passed to pods through mounted volumes or through environment variables.

The following is an example as to how volumeMounts specified in a pod's YAML file may be used:

File: secret-pod.yaml
```yaml
apiVersion: v1
kind: Pod  
metadata:  
  name: secret-pod
  namespace: default  
spec:  
  containers:  
  - name: secret-pod
    image: busybox  
    command:  
      - sleep  
      - "10000"  
    volumeMounts:  
    - name: secret-path
      mountPath: "/etc/secret-path"
      readOnly: true  
  restartPolicy: Never  
  volumes:  
  - name: secret-path
    secret:  
      secretName: secret-config     
      items:  
      - key: config.yaml  
        path: config.yaml
        mode: 400
```

Then create the pod.

```
kubectl create -f secret-pod.yaml
```
```
pod/secret-pod created
```

After creating the pod, verify it is ready.

```
kubectl get pods
```
```
NAME                           READY   STATUS    RESTARTS   AGE
secret-pod                     1/1     Running   0          7s
```

Once the pod is ready, exec a shell in the pod container.

```
kubectl exec -it secret-pod -- sh
```

Once you are inside the busybox container, lets have a look at our secrets.

```
/ #
/ # cd /etc/secret-path
/ # ls -l
/ # cat config.yaml
```

[Back](lab06.md)


# Pass Secrets to a pod through an environment variable.

Now lets do an example where we can get these secrets through an environment variable.

File: secret-pod-env.yaml


```yaml
apiVersion: v1  
kind: Pod  
metadata:  
  name: secret-pod-env  
spec:  
  containers:  
  - name: secret-pod-env  
    image: busybox  
    command:  
      - sleep  
      - "10000"  
    env:  
      - name: SECRET_CONFIG  
        valueFrom:  
          secretKeyRef:  
            name: secret-config  
            key: config.yaml  
      - name: VARIABLE_EXAMPLE  
        valueFrom:  
          secretKeyRef:  
            name: secret-user-pass  
            key: password
  restartPolicy: Never
```


Now lets create the pod.


```
kubectl create -f secret-pod-env.yaml
```
```
pod/secret-pod-env created
```


Lets go have a look.


```
kubectl exec -it secret-pod-env -- env
```

```
SECRET_CONFIG=apiUrl: https://ks.api.com/api/v1  
username: admin  
password: Password01  
application: applicazione01
VARIABLE_EXAMPLE=Password01

KUBERNETES_SERVICE_PORT_HTTPS=443
```



[Back](lab06.md)

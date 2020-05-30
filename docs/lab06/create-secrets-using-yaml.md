
# Create Secrets using YAML



You may also create secrets with a YAML file. The following is an example:

```
echo admin | base64
```
```
YWRtaW4K
```

```
echo Password01 | base64
```
```
UGFzc3dvcmQwMQo=
```


File: /home/student/secret-user-pass.yaml
```yaml
apiVersion: v1  
kind: Secret  
metadata:  
  name: secret-user-pass  
type: Opaque  
data:  
  username: YWRtaW4K  
  password: UGFzc3dvcmQwMQo=
```

```
kubectl apply -f secret-user-pass.yaml
```


```
secret/secret-user-pass created
```


Additional fields may also be stored in a YAML file.

Use an editor to create secret-config.yaml.

File: /home/student/secret-config.yaml

```yaml
apiVersion: v1  
kind: Secret  
metadata:  
  name: secret-config  
type: Opaque  
stringData:  
  config.yaml:  |-  
    apiUrl: https://kubernetes.api.com/api/v1  
    username: admin  
    password: Password01  
    application: applicazione01
```
Then create the secret with:
```
kubectl create -f secret-config.yaml
```

You may look at the fields by getting the secret in YAML, and then passing the config.yaml field through the decoder.


```
kubectl get secret secret-config -o yaml
echo '[stored value here]' | base64 -d
```

[Back](lab06.md)

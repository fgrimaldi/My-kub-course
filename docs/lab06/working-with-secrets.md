
# Working with Secrets



First, store the secret data in a file. In this example, we will place a username and password in two files encoded with base64.
```
echo -n 'admin' > ./username.txt
```

```
echo -n 'Password01' > ./password.txt
```


The kubectl can package these files into a 'Secret' object on the API server.
```
kubectl create secret generic ks-user-pass --from-file=./username.txt --from-file=./password.txt
```


You can look up secrets with get and describe as follows:


```
kubectl get secrets
kubectl describe secrets/ks-user-pass
```
```
Secrets are masked by default. If you need to obtain the value of a stored secret, you may use the following commands:
```
```
kubectl get secret ks-user-pass -o yaml
```


Then decode the values with:
```
echo '[stored value here]' | base64 -d
```


[Back](lab06.md)

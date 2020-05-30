## kubeconfig

As suggested in the directions at the end of the previous output we will allow a non-root user admin level access to the cluster. Take a quick look at the configuration file once it has been copied and the permissions fixed.

```
root@master:~# exit  
logout
```

Now try to list K8s nodes
```
student@master:~$ kubectl get nodes
```
```
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```
As you can see, you cannot connect to the server because you do not have kubeconfig set.
We copy the kubeconfig file from */etc/kubernetes/admin.conf* to */home/student/.kube/config*


```
student@master:~$ mkdir -p $HOME/.kube
```
```
student@master:~$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```
```
student@master:~$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
```
student@master:~$ less .kube/config
```

```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <CERTIFICATE>
    server: https://10.10.98.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: <CERTIFICATE>
    client-key-data: <CERTIFICATE>
```

starting the kubectl now you will be able to see result:

```
student@master:~$ kubectl get nodes
NAME     STATUS     ROLES    AGE   VERSION
master   NotReady   master   42s   v1.15.0
```

View the current context for kubectl

```
student@master:~$ kubectl config current-context
```

For display clusters defined in the kubeconfig
```
student@master:~$ kubectl config get-contexts
```
```
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   
kubernetes-admin   
```

```
kubernetes-admin@kubernetes
```
To view the current cluster run:
```
student@master:~$ kubectl config get-clusters
```
```
NAME
kubernetes
```

To view your environment's kubeconfig, run the following command:
```
student@master:~$ kubectl config view
```
```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://10.10.98.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```


[Back](lab01.md)

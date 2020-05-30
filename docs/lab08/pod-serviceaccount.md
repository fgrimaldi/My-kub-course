# Create a pod under a specific ServiceAccount



To create a ServiceAccount called jenkins, enter the following command:

```
student@master:~$ kubectl create serviceaccount desotech
```
```
serviceaccount/desotech created
```

You may display detailed information about the service account with the following command:

```
student@master:~$ kubectl get serviceaccounts desotech -o yaml
```
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2018-09-01T07:58:36Z"
  name: desotech
  namespace: default
  resourceVersion: "144044"
  selfLink: /api/v1/namespaces/default/serviceaccounts/desotech
  uid: e6195a39-cd08-40de-ac98-1f4be81a4e39
secrets:
- name: desotech-token-rgffh
```

To see all secrets in the current namespace, input:

```
student@master:~$ kubectl get secrets
```
```
NAME                   TYPE                                  DATA   AGE
default-token-wrztn    kubernetes.io/service-account-token   3      20h
desotech-token-rgffh   kubernetes.io/service-account-token   3      49s
```

To interrogate further, you may output YAML for a particular secret with this command:
`kubectl get secret <token name from previous command>  -o yaml`

```
student@master:~$ kubectl get secret desotech-token-rgffh -o yaml
```
```yaml
apiVersion: v1
data:
  ca.crt: <OMITTED>
  namespace: ZGVmYXVsdA==
  token: <OMITTED>
kind: Secret
metadata:
  annotations:
    kubernetes.io/service-account.name: desotech
    kubernetes.io/service-account.uid: e6195a39-cd08-40de-ac98-1f4be81a4e39
  creationTimestamp: "2018-09-01T07:58:36Z"
  name: desotech-token-rgffh
  namespace: default
  resourceVersion: "144043"
  selfLink: /api/v1/namespaces/default/secrets/desotech-token-rgffh
  uid: b720d187-b9c0-4384-a3c3-2db17bb0636b
type: kubernetes.io/service-account-token
```

To see all ServiceAccounts in the current namespace:

```
student@master:~$ kubectl get serviceaccounts
```
```
NAME       SECRETS   AGE
default    1         20h
desotech   1         2m46s
```

To interrogate a ServiceAccount:

```
student@master:~$ kubectl describe serviceaccount desotech
```
```
Name:                desotech
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   desotech-token-rgffh
Tokens:              desotech-token-rgffh
Events:              <none>
```

To run a pod under a specific ServiceAccount, create a YAML file as follows:

File: /home/student/pod-serviceaccount.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-under-serviceaccount
spec:
  serviceAccountName: desotech
  containers:
  - name: alpine
    image: alpine
    command:
    - "sh"
    - "-c"
    - "sleep 10000"
```

To run the pod, enter this command:

```
student@master:~$ kubectl apply -f pod-serviceaccount.yaml
```
```
pod/pod-under-serviceaccount created
```

You may interrogate the pod with the describe verb:


```
student@master:~$ kubectl describe po/pod-under-serviceaccount
```
```
Name:         pod-under-serviceaccount
. . .
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from desotech-token-rgffh (ro)
. . .
Volumes:
  desotech-token-rgffh:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  desotech-token-rgffh
    Optional:    false
. . .
```

To run a shell inside the container, input:

```
student@master:~$ kubectl exec -it pod-under-serviceaccount -- sh
```
```
/ #
```

Once inside the pod container, you may output the token with the following command:

```
/ # cat /var/run/secrets/kubernetes.io/serviceaccount/token
```
```
<OMITTED>
```

Let's clean this labs

Deleting service account will be deleted the secrets too.

```
student@master:~$ kubectl delete sa desotech
```
```
serviceaccount "desotech" deleted
```

```
student@master:~$ kubectl delete po/pod-under-serviceaccount
```
```
pod "pod-under-serviceaccount" deleted
```

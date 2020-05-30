# RBAC with an Example

Create a ServiceAccount, say 'readonlyuser'.

```
student@master:~$ kubectl create serviceaccount readonlyuser
```
```
serviceaccount/readonlyuser created
```

Create cluster role, say `readonlyuser`.

```
student@master:~$ kubectl create clusterrole readonlyuser --verb=get --verb=list --verb=watch --resource=pods
```
```
clusterrole.rbac.authorization.k8s.io/readonlyuser created

```
Create cluster role binding , say `readonlyuser`.

```
student@master:~$ kubectl create clusterrolebinding readonlyuser --serviceaccount=default:readonlyuser --clusterrole=readonlyuser
```
```
clusterrolebinding.rbac.authorization.k8s.io/readonlyuser created
```

Now get the token from secret of ServiceAccount we have created before. we will use this token to authenticate user.

```
student@master:~$ TOKEN=$(kubectl describe secrets "$(kubectl describe serviceaccount readonlyuser | grep -i
Tokens | awk '{print $2}')" | grep token: | awk '{print $2}')
```

```
student@master:~$ echo $TOKEN
```
```
<OMITTED>
```

Now set the credentials for the user in kube config file. I am using 'desotech' as username.

```
student@master:~$ kubectl config set-credentials desotech --token=$TOKEN
```
```
User "desotech" set.
```

Now Create a Context say context-pod-readonly, i am using my clustername 'kubernetes' here.

```
student@master:~$ kubectl config set-context context-pod-readonly --cluster=kubernetes --user=desotech
```
```
Context "context-pod-readonly" created.
```

Finally use the context .

```
student@master:~$ kubectl config use-context context-pod-readonly
```
```
Switched to context "context-pod-readonly".
```
```
kubectl config set-context --current --namespace=test-ns
```
```
Context "context-pod-readonly" modified.
```

And that's it. Now one can execute kubectl get pods --all-namespaces. one can also check the access by executing as given:


```
student@master:~$ kubectl auth can-i get pods --all-namespaces
```
```
yes
```

```
student@master:~$ kubectl auth can-i create pods
```
```
no
```

```
student@master:~$ kubectl auth can-i delete pods
```
```
no
```
Try to create a pod, the command should fail:

```
student@master:~$ kubectl run nginx --generator=run-pod/v1 --image=nginx
```
```
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:readonlyuser" cannot create resource "pods" in API group "" in the namespace "default"
```
Return to Admin context:
```
student@master:~$ kubectl config use-context kubernetes-admin@kubernetes
```
```
Switched to context "kubernetes-admin@kubernetes".
```
Delete the *context-pod-readonly* context
```
root@0-k8s-master0:~# kubectl config delete-context context-pod-readonly
```
```
deleted context context-pod-readonly from /home/student/.kube/config
```
Delete service account

```
root@0-k8s-master0:~# kubectl delete serviceaccount readonlyuser
```
```
serviceaccount "readonlyuser" deleted
```
Delete ClusterRole
```
root@0-k8s-master0:~# kubectl delete clusterrole readonlyuser
```
```
clusterrole.rbac.authorization.k8s.io "readonlyuser" deleted
```
Delete ClusterRoleBinding
```
root@0-k8s-master0:~# kubectl delete clusterrolebinding readonlyuser
```
```
clusterrolebinding.rbac.authorization.k8s.io "readonlyuser" deleted
```

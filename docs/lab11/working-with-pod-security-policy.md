
# Exercises 14.1: Working with Pod Security Policy

Create ns01 namespace

  
```bash
kubectl create namespace ns01
```

> ```
> namespace "ns01" created
> ```
  

Create the sa01 serviceaccount within the ns01 namespace.

  
```
kubectl create serviceaccount -n ns01 sa01  
```
> ```
> serviceaccount "sa01" created
> ```

Create a rolebinding rb01 binding the cluster role verb edit to the service account sa01.

  
```
kubectl create rolebinding -n ns01 rb01 --clusterrole=edit --serviceaccount=ns01:sa01
```
> ```
> rolebinding.rbac.authorization.k8s.io "rb01" created 
> ```

Now for convenience, create an alias for work within the namespace ns01 with user admin.


```
alias kubeadmin='kubectl -n ns01'
```

And create an alias for work within the namespace ns01 with the serviceaccount sa01.

```
alias kubeuser='kubectl --as=system:serviceaccount:ns01:sa01 -n ns01'
```

## Create the pod security policy.

File: pod-security-policy.yaml

```yaml
apiVersion: policy/v1beta1  
kind: PodSecurityPolicy  
metadata:  
    name: pod-security-policy  
spec:  
    privileged: false 
    # Don't allow privileged pods!  
    seLinux:  
      rule: RunAsAny  
    supplementalGroups:  
      rule: RunAsAny  
    runAsUser:  
      rule: RunAsAny  
    fsGroup:  
      rule: RunAsAny  
    volumes:  
    - '*'
```

Then we will create the Pod Security Policy:

```
kubeadmin create -f pod-security-policy.yaml  
```
> ```
> podsecuritypolicy.policy "pod-security-policy" created
> ```

Check the Pod Security Policy created.

```bash
kubeadmin get podsecuritypolicy 
```


> ```
>NAME DATA CAPS SELINUX RUNASUSER FSGROUP SUPGROUP READONLYROOTFS VOLUMES  
>kube-system true * RunAsAny RunAsAny RunAsAny RunAsAny false *  
>pod-security-policy false RunAsAny RunAsAny RunAsAny RunAsAny false *
> ```

Now we can try to deploy a pod.

File: pod-in-pause.yaml

```yaml
apiVersion: v1  
kind: Pod  
metadata:  
    name: pod-in-pause  
spec:  
    containers:  
    - name: pause  
      image: k8s.gcr.io/pause
```
  
```
kubeuser create -f pod-in-pause.yaml  
```

> ```
>Error from server (Forbidden): error when creating "pod-in-pause.yaml": pods "pod-in-pause" is forbidden: unable to validate against any pod security policy: []
> ```


For explain this error, you should try to use the special command ‘can-i’ for understand if the policy is not being used by the service account sa01.

  
```
kubeuser auth can-i use podsecuritypolicy/pod-security-policy 
```
> ```
> no
> ```

For solve the problem you should create a rolebinding to allow the sa01 service account to use the policy.

Create a role to use the pod-security-policy policy.

```
kubeadmin create role role01 --verb=use --resource=podsecuritypolicy --resource-name=pod-security-policy
```
> ```
> role.rbac.authorization.k8s.io "role01" created
> ```  

Check if the role have been created.

  
```bash
kubeadmin get role  
```
> ```
>NAME AGE  
>role01 18s
> ```
  

Then you will create a rolebinding to bind the role to the service account.


```
kubeadmin create rolebinding rb02 --role=role01 --serviceaccount=ns01:sa01 
```
> ```
> rolebinding.rbac.authorization.k8s.io "rb02" created
> ```

Check if the rolebinding have been created.

```bash
kubeadmin get rolebinding 
```

> ```
> ```NAME AGE  
> ```rb01 29m  
> ```rb02 19s
> ```

Try to create a pod as before.

```
kubeuser create -f pod-in-pause.yaml
```
> ```
> pod "pod-in-pause" created
> ```

Check if the pod have been created.


```bash
kubeuser get pod  
```

> ```
> NAME READY STATUS RESTARTS AGE  
pod-in-pause 1/1 Running 0 19s
> ```

Now you can delete this pod.

```
kubeuser delete po/pod-in-pause 
```
>```
>pod "pod-in-pause" deleted
>```

You should try to deploy a privileged pod.


File: privileged-pod.yaml


```yaml
apiVersion: v1  
kind: Pod  
metadata:  
    name: privileged-pod  
spec:  
    containers:  
    - name: pause  
      image: k8s.gcr.io/pause  
      securityContext:  
        privileged: true
```

Create the pod with the file created. The attempt should fail.

```
kubeuser create -f privileged-pod.yaml  
```
> ```
>Error from server (Forbidden): error when creating "privileged-pod.yaml": pods "privileged-pod" is forbidden: unable to validate against any pod security policy: [spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed]
> ```

You should have the same result with deployment.

File: deploy-in-pause.yaml

```yaml
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: deploy-in-pause  
  labels:  
    app: pod-in-pause  
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: pod-in-pause  
  template:  
    metadata:  
      labels:  
        app: pod-in-pause  
    spec:  
      containers:  
      - name: pod-in-pause  
        image: k8s.gcr.io/pause
```
Create the pod with the file created.

```bash
kubeuser get pod,deploy
```

>```
>NAME DESIRED CURRENT UP-TO-DATE AVAILABLE AGE  
>deployment.extensions/deploy-in-pause 1 0 0 0 27s
>```

The deployment was created successfully but the replicaSet and the pod should not be deployed.

Check the events to see what happened.

```bash
kubeuser get events --sort-by='.metadata.creationTimestamp' 
```
>```
>LAST SEEN FIRST SEEN COUNT NAME KIND SUBOBJECT TYPE REASON SOURCE MESSAGE  
>. . .  
>2m 5m 16 deploy-in-pause-77ccd9db6.159fd58b6784a94f ReplicaSet Warning FailedCreate replicaset-controller Error creating: pods "deploy-in-pause-77ccd9db6-" is forbidden: unable to validate against any pod security policy: []
>```



Delete the deployment

  
```
kubeuser delete deploy/deploy-in-pause  
```
>```
>deployment.extensions "deploy-in-pause" deleted
>```
  

Check if there are any pods running and delete as needed.

  
```
kubeuser get pods  
```

>```
>No resources found.
>```

Check the name of the role.

  
```bash
kubeadmin get role
```
>```
>NAME AGE  
>role01 40m
>```

Create a role binding linking the role that allows use of the policy with the default service account.


```
kubeadmin create rolebinding rb03 --role=role01 --serviceaccount=ns01:default
```
>```
>rolebinding.rbac.authorization.k8s.io "rb03" created
>```

Now reattempt to create the deployment as before.

```
kubeuser create -f deploy-in-pause.yaml
```
>```
>deployment.apps "deploy-in-pause" created
>```

Check the deployment and the pod.

```bash
kubeuser get pod,deploy
```
>``` 
>NAME READY STATUS RESTARTS AGE  
>pod/deploy-in-pause-77ccd9db6-4fqds 1/1 Running 0 46s  
>  
>NAME DESIRED CURRENT UP-TO-DATE AVAILABLE AGE  
>deployment.extensions/deploy-in-pause 1 1 1 1 46s
>```


[Back](lab11.md)

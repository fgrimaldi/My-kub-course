# Working with Deployments

Deployments are intended to replace Replication Controllers.  They provide the same replication functions (through Replica Sets) and also the ability to rollout changes and roll them back if necessary.

Let’s create a simple Deployment using the same image we’ve been using.  You can copy the rs.yaml file to ds.yaml, and change as follow:

File: /home/student/deploy.yaml

```Yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: deployment-rs
  template:
    metadata:
      labels:
        app: deployment-rs
        environment: dev
    spec:
      containers:
      - name: container01
        image: gcr.io/desotech/nginx:1.16
        ports:
        - containerPort: 80
```

Check the api resources.

```
student@master:~$ kubectl api-resources | grep Deployment
```
```
deployments                       deploy       apps                           true         Deployment
deployments                       deploy       extensions                     true         Deployment
```

We will use the stable apps/v1

```
student@master:~$ kubectl api-versions  | grep apps
```
```
apps/v1
apps/v1beta1
apps/v1beta2
```
Now go ahead and create the Deployment:
```
student@master:~$ kubectl create -f deploy.yaml
```
```
deployment.apps/deployment-test created
```

Now let’s go ahead and describe the Deployment:
```
student@master:~$ kubectl describe deploy deployment-test
```
```
Name:                   deployment-test
Namespace:              default
CreationTimestamp:      Tue, 16 Jul 2019 12:58:13 +0200
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=test-rs
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=test-rs
           environment=dev
  Containers:
   container01:
    Image:        gcr.io/desotech/nginx
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   deployment-test-5bdd7644cd (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  44s   deployment-controller  Scaled up replica set deployment-test-5bdd7644cd to 3
```

As you can see, rather than listing the individual pods, Kubernetes shows us the Replica Set.  Notice that the name of the Replica Set is the Deployment name and a hash value.

```
student@master:~$ kubectl get deploy,rs,pod
```
```
NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/deployment-test   3/3     3            3           100s

NAME                                               DESIRED   CURRENT   READY   AGE
replicaset.extensions/deployment-test-5bdd7644cd   3         3         3       100s

NAME                                   READY   STATUS    RESTARTS   AGE
pod/deployment-test-5bdd7644cd-g5l25   1/1     Running   0          100s
pod/deployment-test-5bdd7644cd-nvc6w   1/1     Running   0          100s
pod/deployment-test-5bdd7644cd-pnvl9   1/1     Running   0          100s
```

As you can see, the Deployment is backed, in this case, by Replica Set deployment-test-5bdd7644cd. If we go ahead and look at the list of actual Pods.

Try to delete ReplicaSet:
```
student@master:~$ kubectl delete rs deployment-test-5bdd7644cd
```
```
replicaset.extensions "deployment-test-5bdd7644cd" deleted
```
Check the state of Ready POD in ReplicaSet
```
student@master:~$ kubectl get rs
```
```
NAME                         DESIRED   CURRENT   READY   AGE
deployment-test-5bdd7644cd   3         3         0       3s
student@master:~$ kubectl get rs
NAME                         DESIRED   CURRENT   READY   AGE
deployment-test-5bdd7644cd   3         3         1       7s
student@master:~$ kubectl get rs
NAME                         DESIRED   CURRENT   READY   AGE
deployment-test-5bdd7644cd   3         3         3       12s
```

List pods
```
student@master:~$ kubectl get pods
```
```
NAME                               READY   STATUS    RESTARTS   AGE
deployment-test-5bdd7644cd-fqcx9   1/1     Running   0          97s
deployment-test-5bdd7644cd-gf2n8   1/1     Running   0          97s
deployment-test-5bdd7644cd-tqwwc   1/1     Running   0          97s
```

Your pod name have been changed, because the desired state of Deployment create a new ReplicaSet. Also ReplicaSet created 3 replicas of POD.

The same behaviour happen if you try to delete pod:
```
student@master:~$ kubectl delete pod deployment-test-5bdd7644cd-fqcx9
```
```
pod "deployment-test-5bdd7644cd-fqcx9" deleted
```
List pods:
```
student@master:~$ kubectl get pod
```
```
NAME                               READY   STATUS    RESTARTS   AGE
deployment-test-5bdd7644cd-bj2qr   1/1     Running   0          15s
deployment-test-5bdd7644cd-gf2n8   1/1     Running   0          4m20s
deployment-test-5bdd7644cd-tqwwc   1/1     Running   0          4m20s
```

Scaling Resources
```
$ kubectl scale --replicas=5 deployment deployment-test                                               
```
The new pod have been created in automatically by ReplicaSet according to Deployment desiderated state.

```
$ kubectl set image deployment deployment-test container01=gcr.io/desotech/nginx:1.17

$ kubectl rollout status deployment deployment-test
```
check your updates
```
$ kubectl rollout history deployment deployment-test
```
return to revision 1
```
$ kubectl rollout undo deployment deployment-test --to-revision=1
```

Let’s clean up before we move on.
```
student@master:~$ kubectl delete deploy deployment-test 
```
```
deployment.extensions "deployment-test" deleted
```

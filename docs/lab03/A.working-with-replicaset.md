# Working with ReplicaSet

A ReplicaSet’s purpose is to maintain a stable set of replica Pods running at any given time. As such, it is often used to guarantee the availability of a specified number of identical Pods.

ReplicaSet is the next-generation Replication Controller. The only difference between a ReplicaSet and a Replication Controller right now is the selector support. ReplicaSet supports the new set-based selector requirements.
Most *kubectl* commands that support Replication Controllers also support ReplicaSets. One exception is the *rolling-update* command. If you want the rolling update functionality please consider using Deployments instead. Also, the *rolling-update* command is imperative whereas Deployments are declarative, so we recommend using Deployments through the rollout command.

While ReplicaSets can be used independently, today it's mainly used by Deployments as a mechanism to orchestrate pod creation, deletion and updates. When you use Deployments you don't have to worry about managing the ReplicaSets that they create. Deployments own and manage their ReplicaSets.

## When to use a ReplicaSet?

A ReplicaSet ensures that a specified number of pod “replicas” are running at any given time. However, a Deployment is a higher-level concept that manages ReplicaSets and provides declarative updates to pods along with a lot of other useful features. Therefore, we recommend using Deployments instead of directly using ReplicaSets, unless you require custom update orchestration or don't require updates at all.

This actually means that you may never need to manipulate ReplicaSet objects: use directly a Deployment and define your application in the spec section.

Replica Sets are a sort of hybrid, in that they are in some ways more powerful than Replication Controllers, and in others they are less powerful.

Replica Sets are declared in essentially the same way as Replication Controllers, except that they have more options for the selector.  For example, we could create a Replica Set like this:

File: /home/student/rs.yaml
```
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: replicaset-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test-rs
  template:
    metadata:
      labels:
        app: test-rs
        environment: dev
    spec:
      containers:
      - name: container01
        image: gcr.io/desotech/nginx
        ports:
        - containerPort: 80
```

In this case, it’s more or less the same as when we were creating the Replication Controller, except we’re using matchLabels instead of label.  But we could just as easily have said:
```
...
spec:
   replicas: 3
   selector:
     matchExpressions:
      - {key: app, operator: In, values: [test-rs, qa-rs, prd-rs]}
      - {key: environment, operator: NotIn, values: [prd]}
  template:
     metadata:
...
```

In this case, we’re looking at two different conditions:

The app label must be test-rs, qa-rs, or prd-rs
The tier label (if it exists) must not be production

You can also see that the apiVersion are no more __core__.
for determine the correct apiVersion run:
```
student@master:~$ kubectl api-resources | grep ReplicaSet
```
```
replicasets                       rs           apps                           true         ReplicaSet
replicasets                       rs           extensions                     true         ReplicaSet
```

You have 2 versions of ReplicaSet (apps and extensions)
>In Kubernetes 1.6, some of these objects were relocated from extensions to specific API groups (e.g. apps). When these objects move out of beta, expect them to be in a specific API group like apps/v1. Using extensions/v1beta1 is becoming deprecated—try to use the specific API group where possible, depending on your Kubernetes cluster version.

We will use apiVersion apps
apps belongs to v1, the stable version, so you will write apps/v1
Check it using *kubectl api-versions* command
```
student@master:~$ kubectl api-versions  | grep apps
```

```
apps/v1
apps/v1beta1
apps/v1beta2
```
Let’s go ahead and create the Replica Set and get a look at it:

```
student@master:~$ kubectl apply -f rs.yaml
```
```
replicaset.apps/replicaset-test created
```
Describe ReplicaSet

```
student@master:~$ kubectl describe rs replicaset-test
```

```
Name:         replicaset-test
Namespace:    default
Selector:     app=test-rs
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"apps/v1","kind":"ReplicaSet","metadata":{"annotations":{},"name":"replicaset-test","namespace":"default"},"spec":{"replicas...
Replicas:     3 current / 3 desired
Pods Status:  3 Running / 0 Waiting / 0 Succeeded / 0 Failed
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
Events:           <none>
```
```
student@master:~$ kubectl get pod
```
```
NAME                    READY   STATUS    RESTARTS   AGE
replicaset-test-4zbrz   1/1     Running   0          92m
replicaset-test-fxhkt   1/1     Running   0          92m
replicaset-test-wdw6g   1/1     Running   0          92m
```

As you can see, the output is pretty much the same as for a Replication Controller (except for the selector), and for most intents and purposes, they are similar.  The major difference is that the rolling-update command works with Replication Controllers, but won’t work with a Replica Set.  This is because Replica Sets are meant to be used as the backend for Deployments.

You will use Deployments on next exercise.

Let’s clean up before we move on.
```
student@master:~$ kubectl delete rs replicaset-test
```
```
replicaset.extensions "replicaset-test" deleted
```
Again, the pods that were created are deleted when we delete the Replica Set.
```
student@master:~$ kubectl get rs,pod
```
```
No resources found.
```

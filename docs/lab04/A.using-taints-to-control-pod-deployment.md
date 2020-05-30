## TAINTS
Taints allow a Kubernetes node to repel a set of pods. In other words, if you want to deploy your pods everywhere except some specific nodes you just need to taint that node.

Better to create a namespace so when we finish this exercise we can delete it without effort.

Create namespace taints
```
student@master:~$ kubectl create namespace taints
```
```
namespace/taints created
```
Set current context with namespace taints
```
student@master:~$ kubectl config set-context --current --namespace taints
```
```
Context "kubernetes-admin@kubernetes" modified.
```
List nodes
```
student@master:~$ kubectl get nodes
```
```
NAME     STATUS   ROLES    AGE   VERSION
master   Ready    master   2d    v1.15.0
worker   Ready    <none>   47h   v1.15.0
```
Let’s take a look at the kubeadm master node for example:

kubectl describe nodes | egrep "Taints:|Name:"


```
student@master:~$ kubectl describe node master | grep Taints
```
```
Taints:             node-role.kubernetes.io/master:NoSchedule
```

## Allow the master server to run non-infrastructure pods.

The master node begins tainted for security and performance reasons. We will allow usage of the node in the training environment, but this step may be skipped in a production environment.

As you can see, this node has a taint `node-role.kubernetes.io/master:NoSchedule`.
The taint has the key `node-role.kubernetes.io/master`, value `null` (which is not shown), and taint effect `NoSchedule`.

So lets’ talk about taint effects in more details.

## Taint Effects
Each taint has one of the following effects:

`NoSchedule` - this means that no pod will be able to schedule onto node unless it has a matching toleration.

`PreferNoSchedule` - this is a “preference” or “soft” version of NoSchedule – the system will try to avoid placing a pod that does not tolerate the taint on the node, but it is not required.

`NoExecute` - the pod will be evicted from the node (if it is already running on the node), and will not be scheduled onto the node (if it is not yet running on the node).

## Run Deployment with a taint master host.

Run an nginx deployment with 1 replica.

```
student@master:~$ kubectl create deployment nginx --image=nginx
```
```
deployment.apps/nginx created
```
Scale up to 2 replica
```
student@master:~$ kubectl scale deployment nginx --replicas=2
```
```
deployment.extensions/nginx scaled
```
Both replica will be started on worker node because there are no toleration with master node.
```
student@master:~$ kubectl describe pod | grep Node:
```
```
Node:           worker/10.10.98.11
Node:           worker/10.10.98.11
```
Try to remove taints from master node. You will use this syntax:
kubectl taint node **name_of_node** **key=value:taint_effect**-
Note the minus sign (-) at the end, which is the syntax to remove a taint.

```
student@master:~$ kubectl taint node master node-role.kubernetes.io/master:NoSchedule-
```
```
node/master untainted
```
Check the node if is untainted
```
student@master:~$ kubectl describe node master | grep Taints
```
```
Taints:             <none>
```
Scale up the deployment to 4 pod
```
student@master:~$ kubectl scale deployment nginx --replicas=4
```
```
deployment.extensions/nginx scaled
```
Now you should see that pods are also scheduled on master node:
```
student@master:~$ kubectl describe pod | grep Node:
```
```
Node:           worker/10.10.98.11
Node:           master/10.10.98.10
Node:           worker/10.10.98.11
Node:           master/10.10.98.10
```
Apply a taint with NoExecute effect.
```
student@master:~$ kubectl taint node master node-role.kubernetes.io/master=:NoExecute
```
```
node/master tainted
```
Check if the master are correctly tainted with NoExecute.
```
student@master:~$ kubectl describe node master | grep Taints
```
```
Taints:             node-role.kubernetes.io/master:NoExecute
```
The pods running on master node will be killed and started again on worker node.
```
student@master:~$ kubectl describe pod | grep Node:
```
```
Node:           worker/10.10.98.11
Node:           worker/10.10.98.11
Node:           worker/10.10.98.11
Node:           worker/10.10.98.11
```
Delete deployment nginx
```
student@master:~$ kubectl delete deployments nginx
```
```
deployment.extensions "nginx" deleted
```
Remove taint to master node.
```
student@master:~$ kubectl taint node master node-role.kubernetes.io/master:NoExecute-
```
```
node/master untainted
```

## Tolerations
In order to schedule to the “tainted” node pod should have some special tolerations, let’s take a look on system pods in kubeadm, for example, etcd pod:
```
student@master:~$ kubectl describe po etcd-master -n kube-system | grep  -i toleration
```
```
Tolerations:       :NoExecute
```

As you can see it has toleration to `:NoExecute` taint, let’s see where this pod has been deployed:
```
student@master:~$ kubectl get po etcd-master -n kube-system -o wide
```
```
NAME          READY   STATUS    RESTARTS   AGE    IP            NODE     NOMINATED NODE   READINESS GATES
etcd-master   1/1     Running   15         2d1h   10.10.98.10   master   <none>           <none>
```

The pod was indeed deployed on the “tainted” node because it “tolerates” `NoSchedule` effect.

Now let’s have some practice: let’s create our own taints and try to deploy the pods on the “tainted” nodes with and without tolerations.

We have a two nodes cluster:
```
student@master:~$ kubectl get nodes
```
```
NAME     STATUS   ROLES    AGE    VERSION
master   Ready    master   2d1h   v1.15.0
worker   Ready    <none>   2d     v1.15.0
```

Imagine that you want worker to be available preferably for testing POC pods. This can be easily done with taints, so let’s create one.


```
student@master:~$ kubectl taint nodes worker node-type=testing:NoSchedule
```
```
node/worker tainted
```
Check the taint applied to worker node.
```
student@master:~$ kubectl describe no worker | grep Taints
```
```
Taints:             node-type=testing:NoSchedule
```

So worker nodes are tainted, so, basically, all pods without tolerations should be deployed to master. Let’s test our theory:
List deployments:

```
student@master:~$ kubectl get deployment
```
```
No resources found.
```
This namespace should be empty.
Create a deployment test with image nginx
```
student@master:~$ kubectl create deployment test --image nginx
```
```
deployment.apps/test created
```
List pods with wide output so you can read the NODE column.
```
student@master:~$ kubectl get po -o wide
```
```
NAME                   READY   STATUS    RESTARTS   AGE    IP               NODE     NOMINATED NODE   READINESS GATES
test-d4df74fc9-d9mbr   1/1     Running   0          2m8s   192.168.219.73   master   <none>           <none>
```
This theory should be confirmed if you scale up the deployment.
So let's scale up to 4 pods.
```
student@master:~$ kubectl scale deployment test --replicas=4
```
```
deployment.extensions/test scaled
```
Check again list of pods.

```
student@master:~$ kubectl get po -o wide
```
```
NAME                   READY   STATUS    RESTARTS   AGE     IP               NODE     NOMINATED NODE   READINESS GATES
test-d4df74fc9-d9mbr   1/1     Running   0          4m38s   192.168.219.73   master   <none>           <none>
test-d4df74fc9-mfzhg   1/1     Running   0          22s     192.168.219.74   master   <none>           <none>
test-d4df74fc9-qgj47   1/1     Running   0          22s     192.168.219.75   master   <none>           <none>
test-d4df74fc9-vcl66   1/1     Running   0          22s     192.168.219.76   master   <none>           <none>
```
Theory works well.
Remove test deployment
```
student@master:~$ kubectl delete deploy test
```
```
deployment.extensions "test" deleted
```
## How you can set tolerations?

Copy file deploy.yaml to deploy-tolerations.yaml and modify as follow:

File: /home/student/deploy-tolerations.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tolerations
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
        image: nginx
        ports:
        - containerPort: 80
      tolerations:
      - key: node-type
        operator: Equal
        value: testing
        effect: NoSchedule
```
The most important part here is:
```
...
      tolerations:
      - key: node-type
        operator: Equal
        value: testing
        effect: NoSchedule
...
```

Let's apply deployments tolerations.
```
student@master:~$ kubectl apply -f deploy-tolerations.yaml
```
```
deployment.apps/tolerations created
```

Copy file deploy.yaml to deploy-no_tolerations.yaml and modify as follow:

File: /home/student/deploy-no_tolerations.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: no-tolerations
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
        image: nginx
        ports:
        - containerPort: 80
```
This deployment doesn't have any tolerations information.
Apply deployments no-tolerations.
```
student@master:~$ kubectl apply -f deploy-no_tolerations.yaml
```
```
deployment.apps/no-tolerations created
```
List pods.
```
student@master:~$ kubectl get po -o wide
```
```
NAME                              READY   STATUS    RESTARTS   AGE     IP                NODE     NOMINATED NODE   READINESS GATES
no-tolerations-5bdd7644cd-969c9   1/1     Running   0          2m42s   192.168.219.78    master   <none>           <none>
no-tolerations-5bdd7644cd-cbvvr   1/1     Running   0          2m42s   192.168.219.79    master   <none>           <none>
no-tolerations-5bdd7644cd-rdwxz   1/1     Running   0          2m42s   192.168.219.80    master   <none>           <none>
tolerations-5d899c5d74-2fnxn      1/1     Running   0          3m22s   192.168.219.77    master   <none>           <none>
tolerations-5d899c5d74-6gpqw      1/1     Running   0          3m22s   192.168.171.117   worker   <none>           <none>
tolerations-5d899c5d74-lzztc      1/1     Running   0          3m22s   192.168.171.116   worker   <none>           <none>
```

You can see, pod's tolerations deployments can run on master and worker node, while pod's no-tolerations deployment will run only master node.

Taints and tolerations can help you to create the dedicated nodes only for some special set of pods (like in kubeadm master node example). Similar to this you can restrict pods to run on some node with a special hardware.

Let's clean everything:

Change the current context namespace
```
student@master:~$ kubectl config set-context --current --namespace default
```
```
Context "kubernetes-admin@kubernetes" modified.
```
Delete the namespace taints.
```
student@master:~$ kubectl delete namespace taints
```
```
namespace "taints" deleted
```

Remove Taints on worker node:
```
student@master:~$ kubectl taint nodes worker node-type:NoSchedule-
```
```
node/worker untainted
```

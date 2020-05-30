# Drain a node

In addition to the ability to taint a node you can also set the status to drain. First view the status, then destroy the existing deployment.  This will migrate all Kubernetes workload from the node. The pods present on the node will be rescheduled to other worker nodes.

List nodes:

```
student@master:~$ kubectl get nodes
```
```
NAME     STATUS   ROLES    AGE    VERSION
master   Ready    master   2d2h   v1.15.0
worker   Ready    <none>   2d1h   v1.15.0
```

Create a deployment drain with image nginx

```
student@master:~$ kubectl create deployment drain --image nginx
```
```
deployment.apps/drain created
```

Scale up drain deployment with 4 pods.

```
student@master:~$ kubectl scale deployment drain --replicas=4
```
```
deployment.extensions/drain scaled
```

List pods again

```
student@master:~$ kubectl get pod -o wide
```
```
NAME                    READY   STATUS    RESTARTS   AGE    IP                NODE     NOMINATED NODE   READINESS GATES
drain-c5cbdfb4f-48z4j   1/1     Running   0          15s    192.168.219.85    master   <none>           <none>
drain-c5cbdfb4f-99575   1/1     Running   0          3m9s   192.168.219.81    master   <none>           <none>
drain-c5cbdfb4f-kgxzr   1/1     Running   0          15s    192.168.171.122   worker   <none>           <none>
drain-c5cbdfb4f-wphfh   1/1     Running   0          15s    192.168.171.121   worker   <none>           <none>
```

Drain worker node:

```
student@master:~$ kubectl drain worker
```
```
node/worker cordoned
error: unable to drain node "worker", aborting command...

There are pending nodes to be drained:
 worker
error: cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): kube-system/calico-node-zd972, kube-system/kube-proxy-5928p
```

> You need to use the command kubectl drain. If you don't want to touch calico and daemonsets you will need this option --ignore-daemonsets.

Verify the state change of the node. It should indicate no new Pods will be scheduled.

List nodes:

```
student@master:~$ kubectl get node
```
```
NAME     STATUS                     ROLES    AGE    VERSION
master   Ready                      master   2d2h   v1.15.0
worker   Ready,SchedulingDisabled   <none>   2d1h   v1.15.0
```
Note that the status reports Ready, even though it will not allow containers to be executed.

List pods:

```
student@master:~$ kubectl get pod -o wide
```
```
NAME                    READY   STATUS    RESTARTS   AGE     IP                NODE     NOMINATED NODE   READINESS GATES
drain-c5cbdfb4f-48z4j   1/1     Running   0          2m25s   192.168.219.85    master   <none>           <none>
drain-c5cbdfb4f-99575   1/1     Running   0          5m19s   192.168.219.81    master   <none>           <none>
drain-c5cbdfb4f-kgxzr   1/1     Running   0          2m25s   192.168.171.122   worker   <none>           <none>
drain-c5cbdfb4f-wphfh   1/1     Running   0          2m25s   192.168.171.121   worker   <none>           <none>
```
## Drain worker node with ignoring daemonsets kind.

DaemonSet are another object that permit to run one pod in every node.

Next chapter will teach you to create a DaemonSet.

```
student@master:~$ kubectl drain worker --ignore-daemonsets
```
```
node/worker already cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/calico-node-zd972, kube-system/kube-proxy-5928p
evicting pod "coredns-5c98db65d4-hlj8c"
evicting pod "drain-c5cbdfb4f-kgxzr"
evicting pod "calico-kube-controllers-59f54d6bbc-clwdg"
evicting pod "coredns-5c98db65d4-7rhpm"
evicting pod "drain-c5cbdfb4f-wphfh"
pod/calico-kube-controllers-59f54d6bbc-clwdg evicted
pod/drain-c5cbdfb4f-wphfh evicted
pod/coredns-5c98db65d4-hlj8c evicted
pod/coredns-5c98db65d4-7rhpm evicted
pod/drain-c5cbdfb4f-kgxzr evicted
node/worker evicted
```

Listing pods, you can see that last 2 pods have been killed and restarted on master node.

```
student@master:~$ kubectl get pod -o wide
```
```
NAME                    READY   STATUS    RESTARTS   AGE     IP               NODE     NOMINATED NODE   READINESS GATES
drain-c5cbdfb4f-48z4j   1/1     Running   0          3m29s   192.168.219.85   master   <none>           <none>
drain-c5cbdfb4f-99575   1/1     Running   0          6m23s   192.168.219.81   master   <none>           <none>
drain-c5cbdfb4f-9tc2m   1/1     Running   0          27s     192.168.219.86   master   <none>           <none>
drain-c5cbdfb4f-b7slq   1/1     Running   0          27s     192.168.219.89   master   <none>           <none>
```

To undo the kubectl drain, you'll need to use the command kubectl uncordon.

```
student@master:~$ kubectl uncordon worker
```
```
node/worker uncordoned
```

Scale down replicas.

```
student@master:~$ kubectl scale deployment drain --replicas=1
```
```
deployment.extensions/drain scaled
```

Scale up again.

```
student@master:~$ kubectl scale deployment drain --replicas=4
```
```
deployment.extensions/drain scaled
```

List pods:

```
student@master:~$ kubectl get pod -o wide        
```
```
NAME                    READY   STATUS    RESTARTS   AGE   IP                NODE     NOMINATED NODE   READINESS GATES
drain-c5cbdfb4f-5hw9g   1/1     Running   0          43s   192.168.219.91    master   <none>           <none>
drain-c5cbdfb4f-99575   1/1     Running   0          19m   192.168.219.81    master   <none>           <none>
drain-c5cbdfb4f-jhl4b   1/1     Running   0          43s   192.168.171.124   worker   <none>           <none>
drain-c5cbdfb4f-qljsn   1/1     Running   0          43s   192.168.171.123   worker   <none>           <none>
```

Both node container 2 pods again.

Remove the deployment a final time to free up resources.

```
student@master:~$ kubectl delete deployment drain
```
```
deployment.extensions "drain" deleted
```

## Examples of commands:

Mark my-node as unschedulable

```
$ kubectl cordon my-node
```

Drain my-node in preparation for maintenance

```
$ kubectl drain my-node
```

Mark my-node as schedulable

```
$ kubectl uncordon my-node
```

Show metrics for a given node

```
$ kubectl top node my-node
```

Display addresses of the master and services

```
$ kubectl cluster-info
```

Dump current cluster state to stdout

```
$ kubectl cluster-info dump
```

Dump current cluster state to /path/to/cluster-state

```
$ kubectl cluster-info dump --output-directory=/path/to/cluster-state
```

If a taint with that key and effect already exists, its value is replaced as specified.

```
$ kubectl taint nodes foo dedicated=special-user:NoSchedule
```

[Back](lab04.md)

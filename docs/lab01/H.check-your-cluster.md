## Check your cluster

You can check on the status of the core master components using the get *componentstatuses* (abbreviated to get *cs*) command:
```
student@master:~$ kubectl get cs
```
```
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok                  
controller-manager   Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
```

The output shows the status of the scheduler, controller-manager, and etcd nodes as well as the most recent messages and errors collected from each service. This is a good first diagnostic check to run if your cluster seems to be operating incorrectly.

Additional connection and service information information can be collected using the cluster-info command:


```
student@master:~$ kubectl cluster-info
```
```
Kubernetes master is running at https://10.10.98.10:6443
KubeDNS is running at https://10.10.98.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Here, the output is showing the endpoint for our Kubernetes master as well as the KubeDNS service endpoint.

To see information about each of the individual nodes that are members of your cluster with a wide output, use the get nodes command:
```
student@master:~$ kubectl get nodes -o wide
```
```
NAME     STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master   Ready    master   12h   v1.15.0   10.10.98.10   <none>        Ubuntu 18.04.2 LTS   4.15.0-54-generic   docker://18.9.7
worker   Ready    <none>   10h   v1.15.0   10.10.98.11   <none>        Ubuntu 18.04.2 LTS   4.15.0-54-generic   docker://18.9.7
```

This lists the status, roles, connection information, and version numbers of the core software running on each of the nodes. If you need to perform maintenance on your cluster nodes or log in to debug an issue, this command can help provide the information you need.

## Viewing Resource and Event Information

To get an overview of the namespaces available within a cluster, use the get namespaces command:
```
student@master:~$ kubectl get namespaces
```
```
NAME              STATUS   AGE
default           Active   12h
kube-node-lease   Active   12h
kube-public       Active   12h
kube-system       Active   12h
```
This shows the namespace partitions defined within the current cluster.

To get an overview of all of the resources running on your cluster, across all namespaces, issue the following command:
```
student@master:~$ kubectl get all --all-namespaces
<output_omitted>
```
The output displays the namespace each resource is deployed in as well as the resource name prefixed by the resource type (output_omitted in the examples shown above). Afterwards, information about the ready and running statuses of each resource helps determine if the processes are operating healthily.

To view the events associated with your resources, use the get events command:

```
student@master:~$ kubectl get events --all-namespaces
<output_omitted>
```
This lists the most recent events logged by your resources, including the event message and the reason it was triggered.
## Install CNI

Reading the last line of kubeadm installation:

```
student@master:~$ sudo cat /root/kubeadm-init.out
```

```
<output_omitted>

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

<output_omitted>
```

Deciding which pod network to use for Container Networking Interface (CNI) should take into account the expected demands on the cluster. There can be only one pod network per cluster, although the CNI-Genie project (Huawei) is trying to change this.

The network must allow container-to-container, pod-to-pod, pod-to-service, and external-to-service communications. As Docker uses host-private networking, using the docker0 virtual bridge and veth interfaces would require being on that host to communicate.

We will use Calico as a network plugin which will allow us to use Network Policies later in the course. Currently Calico does not deploy using CNI by default. The 3.9 version of Calico has one configuration file for flexibility with RBAC. Download the configuration files for. You can apply configuration directly from manifests of Project Calico.

For more information about using Calico, see [Quickstart for Calico on Kubernetes](https://docs.projectcalico.org/latest/getting-started/kubernetes/), Installing Calico for policy and networking, and other related resources.
```
student@master:~$ wget https://docs.projectcalico.org/v3.9/manifests/calico.yaml
```
Use less to page through the file. Look for the IPV4 pool assigned to the containers. There are many different configuration settings in this file. Take a moment to view the entire file. The CALICO_IPV4POOL_CIDR must match the value given to kubeadm init in the following step, whatever the value may be.

```
student@master:~$ less calico.yaml
```
Search CALICO_IPV4POOL_CIDR
For Calico to work correctly, you need to pass --pod-network-cidr=192.168.0.0/16 to kubeadm init or change the CALICO_IPV4POOL_CIDR

```
# Configure the IP Pool from which Pod IPs will be chosen.
- name: CALICO_IPV4POOL_CIDR
value: "192.168.0.0/16"
```

Apply the network plugin configuration to your cluster. Remember to copy the file to the current, non-root user directory first.

```
kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/calico.yaml
```
```
configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
daemonset.apps/calico-node created
serviceaccount/calico-node created
deployment.apps/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
```
Check what yaml created for us

```
student@master:~$ kubectl get customresourcedefinition --namespace kube-system
```
```
NAME                                          CREATED AT
bgpconfigurations.crd.projectcalico.org       2019-07-14T17:31:31Z
bgppeers.crd.projectcalico.org                2019-07-14T17:31:30Z
blockaffinities.crd.projectcalico.org         2019-07-14T17:31:30Z
clusterinformations.crd.projectcalico.org     2019-07-14T17:31:31Z
felixconfigurations.crd.projectcalico.org     2019-07-14T17:31:30Z
globalnetworkpolicies.crd.projectcalico.org   2019-07-14T17:31:31Z
globalnetworksets.crd.projectcalico.org       2019-07-14T17:31:31Z
hostendpoints.crd.projectcalico.org           2019-07-14T17:31:31Z
ipamblocks.crd.projectcalico.org              2019-07-14T17:31:30Z
ipamconfigs.crd.projectcalico.org             2019-07-14T17:31:30Z
ipamhandles.crd.projectcalico.org             2019-07-14T17:31:30Z
ippools.crd.projectcalico.org                 2019-07-14T17:31:31Z
networkpolicies.crd.projectcalico.org         2019-07-14T17:31:31Z
networksets.crd.projectcalico.org             2019-07-14T17:31:31Z
```
```
student@master:~$ kubectl get clusterrole --namespace kube-system | grep calico
```
```
calico-kube-controllers                                                6m54s
calico-node                                                            6m54s
```
```
student@master:~$ kubectl get clusterrolebinding --namespace kube-system | grep calico
```
```
calico-kube-controllers                                7m24s
calico-node                                            7m24s
```
```
student@master:~$ kubectl get ds --namespace kube-system | grep calico                
```
```
calico-node   1         1         1       1            1           beta.kubernetes.io/os=linux   7m59s
```
```
student@master:~$ kubectl get sa --namespace kube-system | grep calico  
```
```
calico-kube-controllers              1         8m21s
calico-node                          1         8m21s
```
```
student@master:~$ kubectl get ds,rs,pod --namespace kube-system | grep calico  
```
```
daemonset.extensions/calico-node   1         1         1       1            1           beta.kubernetes.io/os=linux   8m50s

replicaset.extensions/calico-kube-controllers-59f54d6bbc   1         1         1       8m50s

pod/calico-kube-controllers-59f54d6bbc-tg697   1/1     Running   0          8m49s
pod/calico-node-qv4hn                          1/1     Running   0          8m49s
```
```
student@master:~$ kubectl get pods --namespace kube-system | grep calico
```
```
calico-kube-controllers-59f54d6bbc-tg697   1/1     Running   0          5m24s
calico-node-qv4hn                          1/1     Running   0          5m24s
```

View the available nodes of the cluster. It can take a minute or two for the status to change from Not Ready to Ready.

```
student@master:~$ kubectl get nodes
```
```
NAME     STATUS   ROLES    AGE   VERSION
master   Ready    master   82m   v1.15.0
```

[Back](lab01.md)

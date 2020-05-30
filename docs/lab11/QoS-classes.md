# QoS classes

When Kubernetes creates a Pod it assigns one of these QoS classes to the Pod:

- Guaranteed
= Burstable
= BestEffort

## Create a namespace

Create a namespace so that the resources you create in this exercise are isolated from the rest of your cluster.

```
kubectl create namespace example-qos
```
```
namespace/example-qos created
```


## QoS class of Guaranteed

For a Pod to be given a QoS class of Guaranteed:

- Every Container in the Pod must have a memory limit and a memory request, and they must be the same.
- Every Container in the Pod must have a CPU limit and a CPU request, and they must be the same.

Here is the configuration file for a Pod that has one Container. The Container has a memory limit and a memory request, both equal to 256 MiB. The Container has a CPU limit and a CPU request, both equal to 500 milliCPU:

File: /home/student/qos-guaranteed.yaml

```json
apiVersion: v1
kind: Pod
metadata:
  name: qos-guaranteed
  namespace: example-qos
spec:
  containers:
  - name: qos-guaranteed-ctr
    image: nginx
    resources:
      limits:
        memory: "256Mi"
        cpu: "500m"
      requests:
        memory: "256Mi"
        cpu: "500m"
```


Create the Pod:

```
kubectl apply -f qos-guaranteed.yaml
```
```
pod/qos-guaranteed created
```

View detailed information about the Pod:

```
kubectl  get pod/qos-guaranteed -n example-qos -o yaml | grep qosClass
```
```
  qosClass: Guaranteed
```

The output shows that Kubernetes gave the Pod a QoS class of Guaranteed. The output also verifies that the Pod Container has a memory request that matches its memory limit, and it has a CPU request that matches its CPU limit.

> Note: If a Container specifies its own memory limit, but does not specify a memory request, Kubernetes automatically assigns a memory request that matches the limit. Similarly, if a Container specifies its own CPU limit, but does not specify a CPU request, Kubernetes automatically assigns a CPU request that matches the limit.

Delete your Pod:

```
kubectl delete pod/qos-guaranteed -n example-qos
```
```
pod "qos-guaranteed" deleted
```

## QoS class of Burstable

A Pod is given a QoS class of Burstable if:

- The Pod does not meet the criteria for QoS class Guaranteed.
- At least one Container in the Pod has a memory or CPU request.

Here is the configuration file for a Pod that has one Container. The Container has a memory limit of 256 MiB and a memory request of 128 MiB.

File: /home/student/qos-burstable.yaml

```json
apiVersion: v1
kind: Pod
metadata:
  name: qos-burstable
  namespace: example-qos
spec:
  containers:
  - name: qos-burstable-ctr
    image: nginx
    resources:
      limits:
        memory: "256Mi"
      requests:
        memory: "128Mi"
```


Create the Pod:

```
kubectl apply -f qos-burstable.yaml
```
```
pod/qos-burstable created
```

View detailed information about the Pod:

```
kubectl  get pod/qos-burstable -n example-qos -o yaml | grep qosClass
```
```
  qosClass: Burstable
```
The output shows that Kubernetes gave the Pod a QoS class of Burstable.

Delete your Pod:


```
kubectl delete pod/qos-burstable -n example-qos
```
```
pod "qos-burstable" deleted
```


## QoS class of BestEffort

For a Pod to be given a QoS class of BestEffort, the Containers in the Pod must not have any memory or CPU limits or requests.

Here is the configuration file for a Pod that has one Container. The Container has no memory or CPU limits or requests:

File: /home/student/qos-besteffort.yaml

```json
apiVersion: v1
kind: Pod
metadata:
  name: qos-besteffort
  namespace: example-qos
spec:
  containers:
  - name: qos-besteffort-ctr
    image: nginx
```


Create the Pod:

```
kubectl apply -f qos-besteffort.yaml
```
```
pod/qos-besteffort created
```

View detailed information about the Pod:

```
kubectl  get pod/qos-besteffort -n example-qos -o yaml | grep qosClass
```
```
  qosClass: BestEffort
```
The output shows that Kubernetes gave the Pod a QoS class of BestEffort.

Delete your Pod:


```
kubectl delete pod/qos-besteffort -n example-qos
```
```
pod "qos-besteffort" deleted
```

## Clean up

Delete your namespace:

```
kubectl delete namespace example-qos
```

# Resource Limits for a Namespace


We will create a new namespace and configure another stress deployment to run within. When set stress should not be able to use the previous amount of resources.

Begin by creating a new namespace called ns-with-limit and verify it exists.

## Create Namespace

```
kubectl create namespace ns-with-limit
```
```  
namespace/ns-with-limit created
```

## Create LimitRange

Create a YAML file which limits CPU and memory usage. The kind to use is LimitRange.

File: /home/student/ns-with-limit-range.yaml

```yaml
apiVersion: v1  
kind: LimitRange  
metadata:  
  name: ns-with-limit-range  
spec:  
  limits:  
  - default:  
      cpu: 1  
      memory: 500Mi  
    defaultRequest:  
      cpu: 0.5  
      memory: 100Mi  
    type: Container
```

Create the LimitRange object and assign it to the newly created namespace low-usage-limit. You can use --namespace or -n to declare the namespace.


```
kubectl apply --namespace=ns-with-limit -f ns-with-limit-range.yaml
```
```
limitrange/ns-with-limit-range created
```

Verify it works. Remember that every command needs a namespace and context to work. Defaults are used if not provided.

```
kubectl get LimitRange -n ns-with-limit
```
```
NAME                  CREATED AT
ns-with-limit-range   2019-10-30T09:39:37Z
```

Create an unlimited namespace:

```
kubectl create ns ns-without-limit
```
```
namespace/ns-without-limit created
```

## Create a new deployment in the namespace.

Create a deployment inside namespace `ns-without-limit`

```
kubectl -n ns-without-limit create deployment stress-without-limits --image vish/stress  
deployment.apps/stress-without-limits created
```

```
kubectl get deploy -n ns-without-limit -o json | jq '.items[].spec.template.spec.containers[]'
```
```
{
  "image": "vish/stress",
  "imagePullPolicy": "Always",
  "name": "stress",
  "resources": {},
  "terminationMessagePath": "/dev/termination-log",
  "terminationMessagePolicy": "File"
}
```
As you can see, no limit was applied.

Create a deployment inside namespace `ns-with-limit`

```
kubectl -n ns-with-limit create deployment stress-with-limits --image vish/stress
```
```
deployment.apps/stress-with-limits created
```

```
kubectl get deploy -n ns-with-limit -o json | jq '.items[].spec.template.spec.containers[]'
```
```
{
  "image": "vish/stress",
  "imagePullPolicy": "Always",
  "name": "stress",
  "resources": {},
  "terminationMessagePath": "/dev/termination-log",
  "terminationMessagePolicy": "File"
}
```

```
kubectl -n ns-with-limit get pod
```
```
NAME                                  READY   STATUS    RESTARTS   AGE
stress-with-limits-58cd5bcb68-jc9wf   1/1     Running   0          58m
```

```
kubectl get pod -n ns-with-limit -o json | jq '.items[].spec.containers[].resources'
```
```json
{
  "limits": {
    "cpu": "1",
    "memory": "500Mi"
  },
  "requests": {
    "cpu": "500m",
    "memory": "100Mi"
  }
}
```

```
kubectl get pod -n ns-without-limit -o json | jq '.items[].spec.containers[].resources'
```
```json
{}
```


## Clean up
```
kubectl  delete ns ns-without-limit ns-with-limit
```
```
namespace "ns-without-limit" deleted
namespace "ns-with-limit" deleted
```



[Back](lab11.md)

# Working with CPU and Memory Constraints

## Overview

We will continue working with our cluster, which we built in the previous lab. We will work with resource limits, more with namespaces and then a complex deployment which you can explore to further understand the architecture and relationships.

Use a container called stress, which we will name hog, to generate load. Verify you have a container running.

```
kubectl create deployment stress --image vish/stress  
```

>```
>deployment.apps/stress created  
>```


```bash
kubectl get deployments
```
>```
>NAME READY UP-TO-DATE AVAILABLE AGE  
>stress 1/1 1 1 13s
>```


Use the describe argument to view details, then view the output in YAML format. Note there are no settings limiting resource usage. Instead, there are empty curly brackets.


```
kubectl describe deployment
```

>```  
>Name: stress  
>Namespace: default  
>CreationTimestamp: Sun, 17 Feb 2019 16:56:42 +0000  
>Labels: app=stress  
>Annotations: deployment.kubernetes.io/revision: 1  
><output_omitted>
>```

```
kubectl get deployment stress -o yaml > stress.yaml
```

```yaml
apiVersion: extensions/v1beta1  
kind: Deployment  
metadata:  
<output_omitted>  
  template:  
    metadata:  
      creationTimestamp: null  
      labels:  
        app: stress  
    spec:  
      containers:  
      - image: vish/stress  
        imagePullPolicy: Always  
        name: stress  
        resources: {}  
        terminationMessagePath: /dev/termination-log  
        terminationMessagePolicy: File  
<output_omitted>
```


We will use the YAML output to create our own configuration file. The --export option can be useful to not include unique parameters.


```
vim stress.yaml
```


If you did not use the --export option we will need to remove the status output, creationTimestamp and other settings, as we don’t want to set unique generated parameters. We will also add in memory limits found below.


```
vim stress.yaml
```

```yaml
    spec:  
      containers:  
      - image: vish/stress  
        imagePullPolicy: Always  
        name: stress  
        resources:  
          limits:  
            memory: "4Gi"  
          requests:  
            memory: "2500Mi"  
        terminationMessagePath: /dev/termination-log  
        terminationMessagePolicy: File
```

Replace the deployment using the newly edited file.

```
kubectl replace -f stress.yaml  
```
>```
>deployment.extensions/stress replaced
>```


Verify the change has been made. The deployment should now show resource limits.


```
kubectl get deployment stress -o yaml
```

```yaml
. . .
    spec:  
      containers:  
      - image: vish/stress  
        imagePullPolicy: Always  
        name: stress  
        resources:  
          limits:  
            memory: 4Gi  
          requests:  
            memory: 2500Mi  
        terminationMessagePath: /dev/termination-log  
        terminationMessagePolicy: File
. . .
```


View the STDIO of the stress container. Note how how much memory has been allocated.


```
kubectl get pod 
```
>``` 
>NAME READY STATUS RESTARTS AGE  
>stress-55fcf6b9fb-7j68d 0/1 Pending 0 6m  
>stress-767d9c6fcb-5n7d7 1/1 Running 0 18m
>```

```
kubectl logs stress-767d9c6fcb-5n7d7
```
>```
>I0217 16:56:46.256116 1 main.go:26] Allocating "0" memory, in "4Ki" chunks, with a 1ms sleep between allocations  
>I0217 16:56:46.256215 1 main.go:29] Allocated "0" memory
>```

Open a second and third terminal to access both master and second nodes. Run top to view resource usage. You should not see unusual resource usage at this point.

The dockerd and top processes should be using about the same amount of resources.

The stress command should not be using enough resources to show up.

Edit the hog configuration file and add arguments for stress to consume CPU and memory. The args: entry should be spaces to the same indent as resources:


```
vim stress.yaml
```

```yaml
. . .
        name: stress  
        resources:  
          limits:  
            cpu: "1"  
            memory: "4Gi"  
          requests:  
            cpu: "0.5"  
            memory: "500Mi"  
        args:  
          - -cpus  
          - "2"  
          - -mem-total  
          - "950Mi"  
          - -mem-alloc-size  
          - "100Mi"  
          - -mem-alloc-sleep  
          - "1s"  
        terminationMessagePath: /dev/termination-log
. . .
```


Delete and recreate the deployment. You should see increased CPU usage almost immediately and memory allocation happen in 100M chunks allocated to the stress program via the running top command. Check both nodes as the container could deployed to either.


```
kubectl delete deployment stress 
```
>``` 
>deployment.extensions "stress" deleted
>```

```
kubectl create -f stress.yaml  
```

>```
>deployment.extensions/stress created
>```

[Back](lab11.md)

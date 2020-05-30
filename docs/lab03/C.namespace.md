## Namespaces

Kubernetes namespaces help different projects, teams, or customers to share a Kubernetes cluster.

It does this by providing the following:

1. A scope for Names.
2. A mechanism to attach authorization and policy to a subsection of the cluster.
Use of multiple namespaces is optional.

By default, a Kubernetes cluster will instantiate a `default` namespace when provisioning the cluster to hold the default set of Pods, Services, and Deployments used by the cluster.

Assuming you have a fresh cluster, you can inspect the available namespaces by doing the following:

```
student@master:~$ kubectl get namespaces
```
```
NAME              STATUS   AGE
default           Active   43h
kube-node-lease   Active   43h
kube-public       Active   43h
kube-system       Active   43h
```

You can see the four built-in Namespaces.

## Creating Namespaces

Creating a Namespace can be done with a single command. If you wanted to create a Namespace called ‘development’ you would run:

```
student@master:~$ kubectl create namespace development
```
```
namespace/development created
```
Or you can create a YAML file

File: /home/student/ns-production.yaml
```YAML
kind: Namespace
apiVersion: v1
metadata:
  name: production
  labels:
    name: Production
```
Apply it just like any other Kubernetes resource.
```
student@master:~$ kubectl apply -f ns-production.yaml
```
```
namespace/production created
```

You see all the Namespaces with the following command:
```
student@master:~$ kubectl get namespace
```
```
NAME              STATUS   AGE
default           Active   43h
development       Active   3m22s
kube-node-lease   Active   44h
kube-public       Active   44h
kube-system       Active   44h
production        Active   71s
```

List all namespaces with labels:

```
student@master:~$ kubectl get namespaces --show-labels
```
```
NAME              STATUS   AGE     LABELS
default           Active   44h     <none>
development       Active   5m10s   <none>
kube-node-lease   Active   44h     <none>
kube-public       Active   44h     <none>
kube-system       Active   44h     <none>
production        Active   2m59s   name=Production
```

## Create Deployment in each namespace

A Kubernetes namespace provides the scope for Pods, Services, and Deployments in the cluster.
Users interacting with one namespace do not see the content in another namespace.
To demonstrate this, let’s spin up a simple Deployment in the `development` namespace.

Copy deploy.yaml file to deploy-production.yaml.

File: /home/student/deploy-production.yaml


```YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-test
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: prd-rs
  template:
    metadata:
      labels:
        app: prd-rs
        environment: prd
    spec:
      containers:
      - name: container01
        image: nginx
        ports:
        - containerPort: 80
```

In the metadata maps, just add namespace parameter with production value.

copy deploy-production.yaml to deploy-development.yaml

```YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-test
  namespace: development
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
Apply deployment in production namespace.
```
student@master:~$ kubectl apply -f deploy-production.yaml
```
```
deployment.apps/production-test created
```
Apply deployment in development namespace.
```
student@master:~$ kubectl apply -f deploy-development.yaml
```
```
deployment.apps/deployment-test created
```
List all pods.
```
student@master:~$ kubectl get pods
```
```
No resources found.
```
You do not find any pods, because you are inside *default* namespace.
Pass the flags `--all-namespaces` for find objects created above.

```
student@master:~$ kubectl get deployment --all-namespaces
```
```
NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
development   deployment-test           3/3     3            3           18s
production    production-test           3/3     3            3           24s
<output_omitted>
```

As you can see now you can read the deployments inside the correct namespace.
You can pass `--namespace` flags to every command for launch it inside the namespace.
List deployment of production namespace
```
student@master:~$ kubectl get deployment --namespace production
```
```
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
production-test   3/3     3            3           117s
```
List deployment of development namespace
```
student@master:~$ kubectl get deployment --namespace development
```
```
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
deployment-test   3/3     3            3           117s
```

By default, if you deploy to a cluster without specifying a namespace, kubectl will place the resources within a namespace called __default__. If you want to deploy to a different namespace, you need to specify the desired alternative.

While we can provide the namespace for the creation command, if we’re going to be working with the namespace for more than a few commands, it’s often easier to alter your current context. Changing the namespace associated with your context will automatically apply the namespace specification to any further commands until the context is changed.

To alter your current context’s namespace use the `set-context` command with the `--current` and `--namespace` flags:

```
student@master:~$ kubectl config set-context --current --namespace=production
```
```
Context "kubernetes-admin@kubernetes" modified.
```
Trying now to list deployment without pass flags `--namespace`.

```
student@master:~$ kubectl get deployment
```
```
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
production-test   3/3     3            3           4m6s
```
This will alter the current context to automatically apply future actions to the __production__ namespace.
Try to create a deployment with nginx image withous specify namespace:
```
student@master:~$ kubectl create deploy nginx --image=nginx
```
```
deployment.apps/nginx created
```
List deployment without specifying any namespace.
```
student@master:~$ kubectl get deployment                   
```
```
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
nginx             0/1     1            0           2s
production-test   3/3     3            3           6m1s
```

You can also create several context for helping you to move faster from one to another:

We first check what is the current context:

```
student@master:~$ kubectl config view
```
```Yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://10.10.98.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```
Check which context are you using now
```
student@master:~$ kubectl config current-context
```
```
kubernetes-admin@kubernetes
```

The next step is to define a context for the kubectl client to work in each namespace. The value of “cluster” and “user” fields are copied from the current context.
```
student@master:~$ kubectl config set-context dev --namespace=development \
  --cluster=kubernetes \
  --user=kubernetes-admin
```
```
Context "dev" created.
```
```
student@master:~$ kubectl config set-context prd --namespace=production \
    --cluster=kubernetes \
    --user=kubernetes-admin
```
```
Context "prd" created.
```
By default, the above commands adds two contexts that are saved into file *.kube/config*. You can now view the contexts and alternate against the two new request contexts depending on which namespace you wish to work against.

To view the new contexts:
```
student@master:~$ kubectl config view
```
```Yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://10.10.98.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    namespace: development
    user: kubernetes-admin
  name: dev
- context:
    cluster: kubernetes
    namespace: production
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
- context:
    cluster: kubernetes
    namespace: production
    user: kubernetes-admin
  name: prd
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```

Let’s switch to operate in the development namespace.
```
student@master:~$ kubectl config use-context dev
```
```
Switched to context "dev".
```

You can verify your current context by doing the following:
```
student@master:~$ kubectl config current-context
```
```
dev
```

At this point, all requests we make to the Kubernetes cluster from the command line are scoped to the development namespace.


Let’s create some contents.
```
student@master:~$ kubectl create deploy nginx-dev --image=nginx
```
You will create a deployment of image nginx on development namespace.
```
deployment.apps/nginx-dev created
```
Change context to prd
```
student@master:~$ kubectl config use-context prd
```
```
Switched to context "prd".
```
You will create a deployment of image nginx on production namespace.
```
student@master:~$ kubectl create deploy nginx-prd --image=nginx
```
```
deployment.apps/nginx-prd created
```
List all deployments on all namespaces.
```
student@master:~$ kubectl get deployment --all-namespaces
```
```
NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
development   deployment-test           3/3     3            3           15m
development   nginx-dev                 1/1     1            1           72s
<output_omitted>
production    nginx                     1/1     1            1           10m
production    nginx-prd                 1/1     1            1           30s
production    production-test           3/3     3            3           16m
```
# Delete namespace

You can delete development namespace

```
student@master:~$ kubectl delete namespaces development
```
```
namespace "development" deleted
```
```
student@master:~$ kubectl get deployment --all-namespaces
```
```
NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
<output_omitted>
production    nginx                     1/1     1            1           41m
production    nginx-prd                 1/1     1            1           31m
production    production-test           3/3     3            3           47m
```

Deleting namespace will delete all object inside. Deployments *deployment-test* and *nginx-dev* have been automatically deleted.

You should also delete the context dev
```
student@master:~$ kubectl config delete-context dev
```
```
deleted context dev from /home/student/.kube/config
```
Change to default context.
```
student@master:~$ kubectl config use-context kubernetes-admin@kubernetes
```
```
Switched to context "kubernetes-admin@kubernetes".
```
Delete the context prd
```
student@master:~$ kubectl config  delete-context prd
```
```
deleted context prd from /home/student/.kube/config
```
Now in the kubeconf configuration you will see only default context.
```
student@master:~$ kubectl config view                     
```YAML
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://10.10.98.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    namespace: production
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```
Let's delete production namespace for clean up the labs.    
```
student@master:~$ kubectl delete namespaces production
```
```
namespace "production" deleted
```  

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

# Scheduling Constraints

By the end of this exercise, you should be able to:

 - Manipulate Kubernetes scheduling decisions using label selectors, node affinity, and taints
 - Create resource requests to ensure Kubernetes doesn't schedule more pods on a host than it can support

## Creating Hard Constraints with Label Selectors

Sometimes, we want a deployment to only schedule pods on a subset of nodes in our cluster, for instance if those pods need specific host configurations or hardware availability. We can create hard constraints on Kubernetes' scheduling decisions using *label selectors*.

1.  Suppose we want all the pods for a given deployment to get scheduled on nodes provisioned with powerful GPUs; further suppose `ucp-node-1` is the only such node in our cluster. Give `ucp-node-1` a Kubernetes label so we can direct our workloads there specifically:

    ```bash
    [centos@infra ~]$ kubectl label nodes ucp-node-1 gpu=true
    ```

    The label name (`gpu`) and value (`true`) are arbitrary and up to you to define in an easily readable manner.

2.  Check that `ucp-node-1` got the label you just applied:

    ```bash
    [centos@infra ~]$ kubectl describe node ucp-node-1

    Name:               ucp-node-1
    Roles:              <none>
    Labels:             beta.kubernetes.io/arch=amd64
                        beta.kubernetes.io/os=linux
                        com.docker.ucp.collection=shared
                        com.docker.ucp.collection.root=true
                        com.docker.ucp.collection.shared=true
                        com.docker.ucp.collection.swarm=true
                        gpu=true
                        kubernetes.io/hostname=ucp-node-1

    ...

    ```

    You should be able to see `gpu=true` in the `Labels:` list.

3.  On `infra`, create a file `deployment-gpu.yaml` with the following content:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gpu-deployment
      namespace: default
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: gpu-pods
      template:
        metadata:
          labels:
            app: gpu-pods
        spec:
          containers:
          - name: nginx
            image: nginx:1.9.1
          - name: pinger
            image: centos:7
            command: ["ping", "8.8.8.8"]
          nodeSelector:
            gpu: "true"
    ```

    Notice this is nearly identical to `deployment.yaml` from the last exercise; we changed the deployment name and pod labels just to avoid any name collisions, but the only substantial difference is the addition of the `nodeSelector` key in the pod specification. All these pods must be scheduled on nodes that bear the `gpu` label, set to a value of `"true"`; if there were multiple entries under `nodeSelector`, they must *all* be satisfied (ie, they are 'ANDed' together).

4.  Create your deployment with `kubectl create -f deployment-gpu.yaml`. On your UCP dashboard, navigate to **Kubernetes -> Pods**, and you should be able to see all three of your pods scheduled on `ucp-node-1`.

5.  Scale up your deployment to 10 replicas like we did in the last exercise, and check your dashboard again; no matter how many replicas you scale this deployment up to, they'll only ever get scheduled on nodes with `gpu=true`, which at the moment is only `ucp-node-1`.

6.  Delete your deployment with `kubectl delete -f deployment-gpu.yaml`.

## Creating Soft Constraints with Node Affinity

Sometimes, we would like to suggest where to schedule pods, but not strictly require this scheduling. For this, we can use a more flexible syntax for scheduling influence, that allows us to define soft as well as hard *node affinity*.

1.  On `infra`, create a file `deployment-ssd.yaml`:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: ssd-deployment
      namespace: default
    spec:
      replicas: 10
      selector:
        matchLabels:
          app: ssd-pods
      template:
        metadata:
          labels:
            app: ssd-pods
        spec:
          containers:
          - name: nginx
            image: nginx:1.9.1
          - name: pinger
            image: centos:7
            command: ["ping", "8.8.8.8"]
          affinity:
            nodeAffinity:
              preferredDuringSchedulingIgnoredDuringExecution:
              - weight: 1
                preference:
                  matchExpressions:
                  - key: ssd
                    operator: In
                    values:
                    - "true"
    ```

    This is again nearly identical to the first `deployment.yaml` we used to make our very first deployment, but now contains the `affinity` block in the pod specification; we'll also ask for 10 pods to see how they get scheduled. The relevant keys are:

    - `preferredDuringSchedulingIgnoredDuringExecution` indicates that this affinity rule is preferred, but not strictly required, when pods are scheduled.
    - `weight` indicates the relative weight of this soft preference (only meaningful in a more complicated example with multiple, possibly conflicting, soft preferences; for each node, the weights of all satisfied soft preferences are added, and the node(s) with the highest score are the most preferred).
    - `preference:matchExpressions` denotes the block where we'll define the preference rule.
    - `key` is the node label name to inspect to evaluate this preference
    - `operator` is the logical operator to evaluate; possible values are `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt` (greater than), and `Lt` (lesser than).
    - `values` is the list of values to compare the value of `key` to via `operator`. So, the above example matches any node which bears an `ssd` label with the value `true`.

2.  Create your new deployment with `kubectl create -f deployment-ssd.yaml`; on UCP, navigate to your pods list to see what nodes your pods got scheduled on; you should see them distributed across your entire cluster, since no node bears the label `ssd=true`. Since this is a soft requirement which cannot be satisfied, the Kubernetes scheduler ignores it and proceeds as normal.

3.  Remove your deployment:

    ```bash
    [centos@infra ~]$ kubectl delete -f deployment-ssd.yaml
    ```

    Wait a few seconds for all the pods to be completely removed, then apply an `ssd` label to `ucp-node-0`, and redeploy:

    ```bash
    [centos@infra ~]$ kubectl label nodes ucp-node-0 ssd=true
    [centos@infra ~]$ kubectl create -f deployment-ssd.yaml
    ```

    Revisit your pod list in UCP; the 10 pods for this deployment have been weighted towards `ucp-node-0`. Note that while `ucp-node-0` should be hosting most of your deployment's pods, it probably isn't hosting *all* of them. When Kubernetes applies soft scheduling constraints, they are combined in a weighted sum of priorities with the scheduler's built-in priority functions that discourage putting many pods for the same controller on a single node. In cases like this one, where the number of pods (10) for our deployment is much greater than the number of preferred nodes (1), you'll usually see at least some pods getting scheduled off-preference.

4.  Clean up by deleting this deployment:

    ```bash
    [centos@infra ~]$ kubectl delete -f deployment-ssd.yaml
    ```

## Scheduling with Taints & Tolerations

So far, the scheduling controls we've seen are applied to pods to 'attract' them to desirable nodes; the concept of *taints* allow us to invert this logic, and apply configuration to nodes that 'repel' pods from these nodes, either strictly or more flexibly.

1.  Apply a taint to `ucp-node-0`:

    ```bash
    [centos@infra ~]$ kubectl taint nodes ucp-node-0 myKey=myValue:NoSchedule
    ```

    Note that `myKey` and `myValue` are an arbitrary key/value pair; you can name them anything you like, and we'll use them to make exceptions to this taint later. The `:NoScheduler` token is the *taint effect* that denotes the effect of this taint; in this case, we are discouraging scheduling on the tainted node.

2.  Recreate a previous deployment with `kubectl create -f deployment.yaml`. Visit your pods list on UCP, and you'll see that none of your pods have been scheduled on `ucp-node-0`. Delete this deployment as above, `kubectl delete -f deployment.yaml`.

3.  Modify `deployment.yaml` to define a *toleration* for your pods:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: demo-deployment
      namespace: default
    spec:
      replicas: 10
      selector:
        matchLabels:
          app: demo-pods
      template:
        metadata:
          labels:
            app: demo-pods
        spec:
          containers:
          - name: nginx
            image: nginx:1.7.9
          - name: pinger
            image: centos:7
            command: ["ping", "8.8.8.8"]
          tolerations:
          - key: "myKey"
            operator: "Equal"
            value: "myValue"
            effect: "NoSchedule"
    ```

    This is exactly the same as your original `deployment.yaml`, but for the `tolerations` block in the pod spec at the end. This toleration tells Kubernetes to ignore a taint with key `myKey` bearing value `myValue` with taint effect `NoSchedule`. Create your deployment the same as above, and check the UCP dashboard; this time, pods can be scheduled on `ucp-node-0` despite the taint.

4.  Apply another taint, this time to `ucp-node-1`:

    ```bash
    [centos@infra ~]$ kubectl taint nodes ucp-node-1 anotherKey=anotherValue:NoExecute
    ```

    Visit your pods list in UCP again - what's happening? When a `:NoExecute` taint is applied to a node, existing pods are evicted if they don't have a toleration allowing them to ignore the taint.

5.  Remove both taints to allow regular scheduling in future exercises, as well as your deployment:

    ```bash
    [centos@infra ~]$ kubectl taint nodes ucp-node-0 myKey:NoSchedule-
    [centos@infra ~]$ kubectl taint nodes ucp-node-1 anotherKey:NoExecute-
    [centos@infra ~]$ kubectl delete -f deployment.yaml
    ```

## Scheduling with Resource Requirements

One crucial best practice for scheduling workloads, particularly in high density or production environments, is making sure nodes aren't overprovisioned with too many pods for their memory and CPU to support. In order to prevent this from happening, we can define *requests* for these resources on a per-container basis, and *limits* for how much of these resources each container can consume. Kube's scheduler will refuse to schedule more pods on a node once all its resources have been taken up by the requests of currently scheduled pods.

1.  Create a file `deployment-mem.yaml`:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: demo-deployment
      namespace: default
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: demo-pods
      template:
        metadata:
          labels:
            app: demo-pods
        spec:
          containers:
          - name: nginx
            image: nginx:1.7.9
            resources:
              requests:
                memory: "1Gi"
          - name: pinger
            image: centos:7
            command: ["ping", "8.8.8.8"]
            resources:
              requests:
                memory: "1Gi"
    ```

    This is again the exact same deployment as our original `deployment.yaml`, but now with the added `resources` block to each container definition. `requests:memory` in this block tells the Kube scheduler to make sure there's at least 1Gi (in this case) of memory available on a node before scheduling this pod there; since this reservation appears in two containers in the pod, a node needs a full 2 Gi of memory available before it can host a pod for this deployment.

2.  Create this deployment as usual: `kubectl create -f deployment-mem.yaml`. The pods list on UCP will show pods scheduled across your cluster as normal.

4.  Pick any of these pending pods, and describe it back on your `infra` node:

    ```bash
    [centos@infra ~]$ kubectl describe pod <pod ID>

    ...
    Events:
      Type     Reason            ...  Message
      ----     ------            ...  -------
      Warning  FailedScheduling  ...  0/3 nodes are available: 3 Insufficient memory.
    ```

    Kubernetes is refusing to schedule all the pods for this deployment, as there isn't enough memory available across your cluster to satisfy the memory requests of all of them.

    Tear down this deployment with `kubectl delete -f deployment-mem.yaml`.

5.  With our current configuration, Kubernetes is prevented from scheduling too many pods on a single host - but nothing currently prevents any container from consuming an arbitrarily large amount of memory once it's scheduled. If we want to really protect against out-of-memory problems, we also have to specify a memory *limit* for each container. Create a new deployment based on a container that will generate 2 Gi of memory pressure to illustrate this:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: demo-deployment
      namespace: default
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: demo-pods
      template:
        metadata:
          labels:
            app: demo-pods
        spec:
          containers:
          - name: memory-pressure
            image: training/stress:2.1
            args: ["--vm", "1", "--vm-bytes", "2048M", "--timeout", "15"]
            resources:
              requests:
                memory: "1Gi"
              limits:
                memory: "1Gi"
    ```

    Create this deployment as usual, then list your pods:

    ```bash
    [centos@infra ~]$ kubectl get pods

    NAME                               READY   STATUS      RESTARTS   AGE
    demo-deployment-54ffcd878b-p9dtc   0/1     OOMKilled   1          6s
    ```

    The pod declared for this deployment is immediately killed off with an OOM (Out Of Memory) Killed status; the 2 Gi of memory it attempts to allocate exceeds the `limit:memory` we specified for this container, so the container runtime kills it off before it overwhelms the resources available on the host.

6.  Finally, clean up by removing this deployment, as above.

## Conclusion

In this exercise, we took a quick tour of the most important methods of controlling and manipulating scheduling decisions in Kubernetes; please refer to the documentation for each feature for full lists of all related flags and options. When applying scheduling constraints in Kubernetes as in any orchestrator, it's important not to over-constrain your scheduler; if there is only a short list of nodes that Kubernetes is allowed to schedule pods on and some or all of them go down, Kubernetes will not be able to reschedule those over-constrained pods and your deployments will begin to suffer outages. Consider using flexible node affinities to encourage optimal scheduling, but allow for pod migration in an emergency. Finally, don't neglect to apply memory requests and limits to your production workloads; without these, it's easy to end up over-provisioning nodes, causing their performance to degrade or processes to be unpredictably killed as memory is exhausted.

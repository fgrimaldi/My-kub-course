# Deploy Kube State Metrics

kube-state-metrics is a simple service that listens to the Kubernetes API server and generates metrics about the state of the objects. It is not focused on the health of the individual Kubernetes components, but rather on the health of the various objects inside, such as deployments, nodes and pods.

The metrics are exported through the Prometheus golang client on the HTTP endpoint /metrics on the listening port (default 80). They are served either as plaintext or protobuf depending on the Accept header. They are designed to be consumed either by Prometheus itself or by a scraper that is compatible with scraping a Prometheus client endpoint. You can also open /metrics in a browser to see the raw metrics.

```bash
kubectl apply -f kube-state-metrics/
```

> ```console
> namespace/monitoring unchanged
> clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics > created
> clusterrole.rbac.authorization.k8s.io/kube-state-metrics created
> rolebinding.rbac.authorization.k8s.io/kube-state-metrics created
> role.rbac.authorization.k8s.io/kube-state-metrics-resizer created
> serviceaccount/kube-state-metrics created
> deployment.apps/kube-state-metrics created
> service/kube-state-metrics created
> ```

This will create the following:

1. Service account, cluster-role and cluster-role-binding needed for kube-state-metrics.
2. Kube-state-metrics deployment with 1 replica running.
3. In-cluster service which will be scraped by prometheus for metrics. ( Note the annotion attached to it.

```bash
kubectl get pods -l k8s-app=kube-state-metrics -n monitoring
```

> ```console
> NAME                                  READY   STATUS    RESTARTS   AGE
> kube-state-metrics-78c669695b-sgt94   2/2     Running   0          65s
> ```

```bash
kubectl get svc  -l k8s-app=kube-state-metrics -n monitoring
```

> ```console
> NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
> kube-state-metrics   ClusterIP   10.107.1.146   <none>        8080/TCP,8081/TCP   100s
> ```


[Back](lab14.md)

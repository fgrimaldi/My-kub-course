# Release Models in Kubernetes

Kubernetes' *label selectors* and separation between service and deployment objects give us a built in mechanism to switch and load balance routing to our pods that does not rely on an external load balancer. By the end of this exercise, you should be able to:

 - Configure Kubernetes label selectors for canary and blue / green releases of deployments.

## Blue / Green Releases

1.  Create 'blue' and 'green' deployments based on `hermedia/photopet` and `:2.0` using the following yaml:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: green
      namespace: default
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: green
      template:
        metadata:
          labels:
            app: green
        spec:
          containers:
          - name: green
            image: hermedia/photopet:1.0
            ports:
            - containerPort: 80
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: blue
      namespace: default
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: blue
      template:
        metadata:
          labels:
            app: blue
        spec:
          containers:
          - name: blue
            image: hermedia/photopet:2.0
            ports:
            - containerPort: 80
    ```

2.  Create a `NodePort` service that points to the 'green' deployment:

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: bluegreen
      namespace: default
    spec:
      type: NodePort
      selector:
          app: green
      ports:
      - port: 8080
        targetPort: 80
    ```

Note the `selector: app: green` section; this service is pointing exclusively at pods with the `app: green` label.

3.  Find the public port selected by your `NodePort` service, and visit your 'green' deployment at `<manager public IP>:<NodePort>`. You should see the goats of version 1.0 of your app.

4.  Now let's flip the routing to our 'blue' deployment.


```yaml
apiVersion: v1
kind: Service
metadata:
  name: bluegreen
  namespace: default
spec:
  type: NodePort
  selector:
      app: blue
  ports:
  - port: 8080
    targetPort: 80
```

5.  In the yaml presented, you should change `selector: app: green` to `app: blue`, and **Save**.

6.  Refresh your browser at `<manager public IP>:<NodePort>`. The `NodePort` service now label-matches the 'blue' pods, and directs traffic there. (If the new version doesn't appear, try clearing your browser cache or using a private or 'incognito' historyless browser, or `curl`ing from the command line instead).

7.  Remove your 'blue' and 'green' deployments and your 'bluegreen' service to clean up.

## Canary Releases

1.  Create 'production' and 'canary' deployments similar to the 'blue' and 'green' deployments above:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: production
      namespace: default
    spec:
      replicas: 4
      selector:
        matchLabels:
          app: photopet
          stream: stable
      template:
        metadata:
          labels:
            app: photopet
            stream: stable
        spec:
          containers:
          - name: production
            image: hermedia/photopet:2.0
            ports:
            - containerPort: 80
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: canary
      namespace: default
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: photopet
          stream: canary
      template:
        metadata:
          labels:
            app: photopet
            stream: canary
        spec:
          containers:
          - name: photopet
            image: training/photopet:2.0
            ports:
            - containerPort: 80
    ```

Note how we've given our 'canary' deployment the same label `app: photopet` as our main 'production' deployment; this way, when we point a service at this label, the service will match and route to both 'production' and 'canary' pods. We've also added in an optional `stream` label - this is not actually necessary to make this example work, but it is a best practice which will let us tell 'production' and 'canary' pods apart by label if we need to for more sophisticated environments.

2.  Create a `NodePort` service that matches the `app: photopet` label:

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: canaryservice
      namespace: default
    spec:
      type: NodePort
      selector:
          app: photopet
      ports:
      - port: 8080
        targetPort: 80
    ```

3.  Find the `NodePort` port for your 'canaryservice' service, and `curl` it at `<manager public IP>:<NodePort>`; you should see the HTML for either your 'production' or 'canary' deployments. Keep `curl`ing a bunch of times; the `NodePort` service will randomly spread your traffic across all the pods its label selector matches, which in this case should be the four 'production' pods and the one 'canary' pod (remember, it's *random* load balancing in this case, unlike the nginx defaults; you may have to `curl` more than 5 times to hit your canary).

4.  Clean up by removing your 'production' and 'canary' deployments, and your 'canaryservice' service.

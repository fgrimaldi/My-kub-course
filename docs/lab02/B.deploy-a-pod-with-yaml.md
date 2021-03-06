# Creating the pod using the YAML file

The first step, of course, is to go ahead and create a text file. Call it pod.yaml and add the following text, just as we specified it earlier:

File: /home/student/pod.yaml

```
---
apiVersion: v1
kind: Pod
metadata:
  name: website
  labels:
    app: application01
spec:
  containers:
    - name: nginx
      image: gcr.io/desotech/nginx
      ports:
        - containerPort: 80
```

Save the file, and tell Kubernetes to create its contents using Imperative approach:
```
student@master:~$ kubectl create -f pod.yaml
```
```
pod/website created
```

As you can see, K8s references the name we gave the Pod. You can see that if you ask for a list of the pods:
```
student@master:~$ kubectl get po
```
```
NAME      READY   STATUS    RESTARTS   AGE
website   0/1     ContainerCreating   0          7s
```
If you check early enough, you can see that the pod is still being created. After a few seconds, you should see the containers running:
```
student@master:~$ kubectl get po
```
```
NAME      READY   STATUS    RESTARTS   AGE
website   1/1     Running   0          43s
```

Try to describe the schedule processes and information of the Pod:
```
student@master:~$ kubectl describe pod/website
```
```
Name:         website
Namespace:    default
Priority:     0
Node:         worker/10.10.98.11
Start Time:   Mon, 15 Jul 2019 07:33:00 +0200
Labels:       app=application01
Annotations:  cni.projectcalico.org/podIP: 192.168.171.65/32
Status:       Running
IP:           192.168.171.65
Containers:
  nginx:
    Container ID:   docker://171223906f71fa1fa3775a14ac011d601ee8be8ee9a57b26b8a72f47ee93db6d
    Image:          gcr.io/desotech/nginx
    Image ID:       docker-pullable://nginx@sha256:48cbeee0cb0a3b5e885e36222f969e0a2f41819a68e07aeb6631ca7cb356fed1
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 15 Jul 2019 07:33:15 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-nkgdd (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-nkgdd:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-nkgdd
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  4m31s  default-scheduler  Successfully assigned default/website to worker
  Normal  Pulling    4m29s  kubelet, worker    Pulling image "nginx"
  Normal  Pulled     4m22s  kubelet, worker    Successfully pulled image "nginx"
  Normal  Created    4m17s  kubelet, worker    Created container nginx
  Normal  Started    4m16s  kubelet, worker    Started container nginx
```

You can edit the YAML of the pod directly using *kubectl edit*
Change the image from nginx to httpd
```
student@master:~$ kubectl edit pod/website
```

From:
```
spec:
  containers:
  - image: gcr.io/desotech/nginx
    imagePullPolicy: Always
    name: nginx
    ports:
    - containerPort: 80
      protocol: TCP
```
To:
```
spec:
  containers:
  - image: gcr.io/desotech/httpd
    imagePullPolicy: Always
    name: nginx
    ports:
    - containerPort: 80
      protocol: TCP
```     

When you save the file (if you are using vim, you can do :wq)
You will obtain the following result:
```   
pod/website edited
```
Try to describe your POD filtering only Image.

```
student@master:~$ kubectl describe pod/website | grep Image:
```
```
    Image:          gcr.io/desotech/httpd
```
As you can see, the image are changed by nginx to httpd
The nginx container had been killed and created a new one with httpd.

[Back](lab02.md)

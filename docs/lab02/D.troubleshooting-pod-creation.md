

## Troubleshooting pod creation

Sometimes, of course, things don’t go as you expect. Maybe you’ve got a networking issue, or you’ve mistyped something in your YAML file. You might see an error like this:
```
student@master:~$ kubectl get pod
```
```
NAME               READY   STATUS         RESTARTS   AGE
nginx-with-error   0/1     ErrImagePull   0          10s
```
or
```
student@master:~$ kubectl get pod
```
```
NAME               READY   STATUS             RESTARTS   AGE
nginx-with-error   1/2     ImagePullBackOff   0          8s
```

In this case, we can see that one of our containers started up just fine, but there was a problem with the other. To track down the problem, we can ask Kubernetes for more information on the Pod:
```
student@master:~$ kubectl describe pod nginx-with-error
```
```
<output_omitted>
  Warning  Failed     11s (x3 over 59s)  kubelet, worker    Failed to pull image "nginx2": rpc error: code = Unknown desc = Error response from daemon: pull access denied for nginx2, repository does not exist or may require 'docker login'
```
As you can see, there’s a lot of information here, but we’re most interested in the Events — specifically, once the warnings and errors start showing up. From here I was able to quickly see that I’d wrong the name of the image, so it was looking for the nginx2, which didn’t exist.

To fix the problem, I first deleted the Pod, then fixed the YAML file and started again. Instead, I could have fixed the repo so that Kubernetes could find what it was looking for, and it would have continued on as though nothing had happened.

Now that we’ve successfully gotten a Pod running, let’s replicate 2 problems and you try to solve it.

## Troubleshooting nr.1

File: /home/student/httpd-with-error.yaml

```
apiVersion: v1  
kind: Pod  
metadata:  
  name: httpd-with-error  
spec:  
  containers:  
  - name: web  
    image: gcr.io/desotech/httpd2.4  
    ports:  
    - containerPort: 80  

```
```
student@master:~$ kubectl apply -f httpd-with-error.yaml
```
```
pod/httpd-with-error created
```

Use kubectl describe for understand your error and fix it.

If you are not able to solve the problem, you can look for a [solution here](troubleshooting-solution01.md)

Modify the file, fix the problem and apply again.

Delete the pod.

## Troubleshooting nr.2

File: /home/student/pod-with-error.yaml
```
apiVersion: v1  
kind: Pod  
metadata:  
  name: pod-with-error  
spec:  
  containers:  
  - name: web  
    image: gcr.io/desotech/nginx  
    ports:  
    - containerPort: 80  
  - name: centos  
    image: gcr.io/desotech/centos:7
```

```
student@master:~$ kubectl apply -f pod-with-error.yaml
```
```
pod/pod-with-error created
```
Use kubectl describe for understand your error and fix it.



If you are not able to solve the problem, you can look for a [solution here](troubleshooting-solution02.md)

Modify the file, fix the problem and apply again.

Delete the pod.

[Back](lab02.md)

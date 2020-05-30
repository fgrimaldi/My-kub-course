#Sidecar pod volume

```
---
# Example of using an InitContainer in place of a GitRepo volume.
# Unilke GitRepo volumes, this approach runs the git command in an init container.
apiVersion: v1
kind: Pod
metadata:
  name: website
  namespace:
  labels:
    run: application01
spec:
  initContainers:
    - name: git-clone
      image: alpine/git
      args: ["clone", "--", "https://github.com/ndecandia/simple-website.git", "/repo"]
      volumeMounts:
        - name: content-data
          mountPath: /repo
  containers:
    - name:  nginx
      image: nginx
      volumeMounts:
        - name: content-data
          mountPath: /usr/share/nginx/html
          readOnly: true
  volumes:
    - name: content-data
      emptyDir: {}
```

```
$ kubectl  get pod
NAME      READY   STATUS     RESTARTS   AGE
website   0/1     Init:0/1   0          5s
```
```
$ kubectl  get pod
NAME      READY   STATUS            RESTARTS   AGE
website   0/1     PodInitializing   0          7s
```
```
$ kubectl  get pod
NAME      READY   STATUS    RESTARTS   AGE
website   1/1     Running   0          30s
```


[Back](lab07.md)

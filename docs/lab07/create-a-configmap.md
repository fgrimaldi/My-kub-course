# Create a ConfigMap

## Overview

Container files are ephemeral, which can be problematic for some applications. Should a container be restarted the files will be lost. In addition, we need a method to share files between containers inside a Pod.

A Volume is a directory accessible to containers in a Pod. Cloud providers offer volumes which persist further than the life of the Pod, such that AWS or GCE volumes could be pre-populated and offered to Pods, or transferred from one Pod to another.

Ceph is also another popular solution for dynamic, persistent volumes.

Unlike current Docker volumes a Kubernetes volume has the lifetime of the Pod, not the containers within. You can also use different types of volumes in the same Pod simultaneously, but Volumes cannot mount in a nested fashion. Each must have their

own mount point. Volumes are declared with spec.volumes and mount points with spec.containers.volumeMounts parameters.

Each particular volume type, 24 currently, may have other restrictions. [https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)



We will also work with a ConfigMap, which is basically a set of key-value pairs. This data can be made available so that a Pod can read the data as environment variables or configuration data. A ConfigMap is similar to a Secret, except they are not base64 byte encoded arrays. They are stored as strings and can be read in serialized form.

## Create a ConfigMap



[https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)




There are three different ways a ConfigMap can ingest data, from a literal value, from a file or from a directory of files.



We will create a ConfigMap containing primary colors. We will create a series of files to ingest into the ConfigMap.

First, we create a directory primary and populate it with four files. Then we create a file in our home directory with our favorite cars vendor.



```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ mkdir vendor  
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ echo f > vendor/ferrari
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ echo l > vendor/lancia  
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ echo t > vendor/tesla  
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ echo h > vendor/honda
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ echo  "know as key" >> vendor/lancia  
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ echo maserati > favorite
```




Now we will create the ConfigMap and populate it with the files we created as well as a literal value from the command line.



```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create configmap cars --from-literal=text=tesla --from-file=./favorite --from-file=./vendor/  
configmap/cars created
```



View how the data is organized inside the cluster.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get configmaps cars

NAME DATA AGE

cars 6 63s
```
```yaml
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get configmaps cars -o yaml
apiVersion: v1
data:
  favorite: |
    maserati
  ferrari: |
    f
  honda: |
    h
  lancia: |
    l
    know as key
  tesla: |
    t
  text: tesla
kind: ConfigMap  
<output_omitted>
```


Now we can create a Pod to use the ConfigMap. In this case a particular parameter is being defined as an environment variable.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim nginx-shell.yaml
```



nginx-shell.yaml


```yaml
apiVersion: v1  
kind: Pod  
metadata:  
  name: nginx-shell  
spec:  
  containers:  
  - name: nginx  
    image: gcr.io/desotech/nginx  
    env:  
    - name: model  
      valueFrom:  
        configMapKeyRef:  
          name: cars  
          key: favorite
```


Create the Pod and view the environmental variable. After you view the parameter, exit out and delete the pod.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f nginx-shell.yaml
pod/nginx-shell created
```
```  
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl exec -it nginx-shell -- /bin/bash -c 'echo $model'
maserati
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete pod nginx-shell
pod "nginx-shell" deleted
```


All variables from a file can be included as environment variables as well. Comment out the previous env: stanza and add a slightly different envFrom to the file. Having new and old code at the same time can be helpful to see and understand the differences. Recreate the Pod, check all variables and delete the pod again. They can be found spread

throughout the environment variable output.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ cp nginx-shell.yaml nginx-shell2.yaml
```
```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim nginx-shell2.yaml
```


file: nginx-shell2.yaml


```yaml
apiVersion: v1  
kind: Pod  
metadata:  
  name: nginx-shell2  
spec:  
  containers:  
  - name: nginx  
    image: gcr.io/desotech/nginx  
    env:  
    - name: model  
      valueFrom:  
        configMapKeyRef:  
          name: cars  
          key: favorite  
    envFrom:  
    - configMapRef:  
        name: cars
```


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f nginx-shell2.yaml  
pod/nginx-shell2 created
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl exec -it nginx-shell2 -- /bin/bash -c 'env'  
lancia=l  
know as key  

model=maserati  

favorite=maserati  

honda=h  

text=tesla  

tesla=t  

ferrari=f  
```  


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete pod nginx-shell2
pod "nginx-shell2" deleted
```


A ConfigMap can also be created from a YAML file. Create one with a few parameters to collect some names.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim configfile-map.yaml
```


File: configfile-map.yaml


```yaml
apiVersion: v1  
kind: ConfigMap  
metadata:  
  name: names  
  namespace: default  
data:  
  name.1:  Nicola  
  name.2:  Marco  
  name.3:  Sophia
```


Create the ConfigMap and verify the settings.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f configfile-map.yaml
configmap/names created
```
```yaml
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get configmaps names -o yaml
apiVersion: v1
data:
  name.1: Nicola
  name.2: Marco
  name.3: Sophia
kind: ConfigMap  
<output_omitted>
```


We will now make the ConfigMap available to a Pod as a mounted volume. You can again comment out the previous environmental settings and add the following new stanza. The containers: and volumes: entries are indented the same number of spaces.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ cp nginx-shell2.yaml nginx-shell3.yaml
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ vim nginx-shell3.yaml
```


File: nginx-shell3.yaml


```yaml
apiVersion: v1  
kind: Pod  
metadata:  
  name: nginx-shell3  
spec:  
  containers:  
  - name: nginx  
    image: gcr.io/desotech/nginx  
    volumeMounts:  
    - name: names-vol  
      mountPath: /etc/names  
  volumes:  
    - name: names-vol  
      configMap:  
        name: names
```


Create the Pod again. Verify the volume exists and the contents of a file within. Due to the lack of a carriage return in the file your next prompt may be on the same line as the output, Sophia.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl create -f nginx-shell3.yaml
pod/nginx-shell3 created
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl exec -it nginx-shell3 -- /bin/bash -c 'df -ha | grep names'
/dev/sda2 20G 8.6G 10G 47% /etc/names
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl exec -it nginx-shell3 -- /bin/bash -c 'cat /etc/names/name.3'
Sophia
```


Delete the Pod and ConfigMaps we were using.


```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete pods nginx-shell3
pod "nginx-shell3" deleted  
```
```bash
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl get configmaps
NAME DATA AGE
cars 6 37m
names 3 8m57s
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete configmaps cars
configmap "cars" deleted
```

```
[student@controller01 ~ (⎈ |kubernetes-admin@kubernetes:default)]$ kubectl delete configmaps names
configmap "names" deleted
```

[Back](lab07.md)

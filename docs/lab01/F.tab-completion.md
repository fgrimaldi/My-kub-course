## Kubectl TAB completion bash

While many objects have short names, a kubectl command can be a lot to type. We will enable bash auto-completion. Begin by adding the settings to the current shell. Then update the /.bashrc file to make it persistent.
```
student@master:~$ source <(kubectl completion bash)
```
```
student@master:~$ echo "source <(kubectl completion bash)" >> ~/.bashrc
```
Test by describing the node again.Type the first three letters of the sub-command then type the Tab key. Auto-completion assumes the default namespace. Pass the namespace first to use auto-completion with a different namespace. By pressing Tab multiple times you will see a list of possible values. Continue typing until a unique name is used. First look at the current node, then look at pods in the kube-system namespace.


```
student@master:~$ kubectl des<Tab> na<Tab> de<Tab>
```
```
student@master:~$ kubectl describe namespaces default
```


```
student@master:~$ kubectl -n kube-s<Tab> g<Tab> p<Tab>
```
```
student@master:~$ kubectl -n kube-system get pod
```
[Back](lab01.md)

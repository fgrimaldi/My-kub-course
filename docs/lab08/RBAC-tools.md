# RBAC Tools

```
kubectl auth can-i list pods
```
```
yes
```

```
kubectl auth can-i list pods --as nicola
```
```
no
```

This first command allows a user to know if he can perform an action. The second command allows an administrator to impersonate a user to know if the targeted user can perform an action. The impersonation can only be used by a user with cluster-admin credentials. Apart from that, we can’t do much more. This is why we will introduce you some open-source projects that allows us to extend the functionalities covered by the kubectl auth can-i command. Before introducing them, we will install some of their dependencies such as Krew and GO.

## Installation of GO

Go is an open source programming language that makes it easy to build simple, reliable, and efficient software. Inspired by C and Pascal, this language was developed by Google from an initial concept of Robert Griesemer, Rob Pike and Ken Thompson.

```
apt-get install -y golang
```

## Installation of KREW

Krew is a tool that makes it easy to use kubectl plugins. Krew helps you discover plugins, install and manage them on your machine. It is similar to tools like apt, dnf or brew. Krew is only compatible with kubectl v1.12 and above.

```
set -x; cd "$(mktemp -d)" && \
curl -fsSLO "https://storage.googleapis.com/krew/latest/krew.{tar.gz,yaml}" && \
tar zxvf krew.tar.gz && ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install \
 --manifest=krew.yaml --archive=krew.tar.gz
```
```
++ mktemp -d
+ cd /tmp/tmp.JVYavPxIY0
+ curl -fsSLO 'https://storage.googleapis.com/krew/latest/krew.{tar.gz,yaml}'
+ tar zxvf krew.tar.gz
Installing plugin: krew
CAVEATS:
\
 |  krew is now installed! To start using kubectl plugins, you need to add
 |  krew's installation directory to your PATH:
 |
 |    * macOS/Linux:
 |      - Add the following to your ~/.bashrc or ~/.zshrc:
 |          export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
 |      - Restart your shell.
 |
 |    * Windows: Add %USERPROFILE%\.krew\bin to your PATH environment variable
 |
 |  Run "kubectl krew" to list krew commands and get help.
 |  You can find documentation at https://github.com/GoogleContainerTools/krew.
/
Installed plugin: krew
```


```
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

## rakkess

This project helps us to know all the authorizations that have been granted to a user. It helps to answer to the question: what can do “jean”? Firstly, let’s install Rakkess:

```
kubectl krew install access-matrix
```
```
Updated the local copy of plugin index.
Installing plugin: access-matrix
CAVEATS:
\
 |  Usage:
 |    kubectl access-matrix
 |
 |  Documentation:
 |    https://github.com/corneliusweig/rakkess/blob/v0.4.1/doc/USAGE.md#usage
/
Installed plugin: access-matrix
```

You can find the documentation on the !(https://github.com/corneliusweig/rakkess)[project Github repository]. Here is an example:

```
kubectl access-matrix -n project-production --as nicola
```
```
NAME                                            LIST  CREATE  UPDATE  DELETE
bindings                                              ✖
configmaps                                      ✖     ✖       ✖       ✖
controllerrevisions.apps                        ✖     ✖       ✖       ✖
cronjobs.batch                                  ✖     ✖       ✖       ✖
daemonsets.apps                                 ✖     ✖       ✖       ✖
deployments.apps                                ✔     ✖       ✖       ✖
```

## kubect-who-can

This project allows us to know who are the users who can perform a specific action. It helps to answer the question: who can do this action? Installation:

```
kubectl krew install who-can
```
```
Updated the local copy of plugin index.
Installing plugin: who-can
CAVEATS:
\
 |  The plugin requires the rights to list (Cluster)Role and (Cluster)RoleBindings.
 |
 |  For usage or examples, run:
 |
 |  $ kubectl who-can -h
/
Installed plugin: who-can
```

You can find the documentation on the !(http://github.com/aquasecurity/kubectl-who-can)[project Github repository]. Here is an example:

```
kubectl who-can list pods -n default
```
```
No subjects found with permissions to list pods assigned through RoleBindings

CLUSTERROLEBINDING                           SUBJECT                         TYPE            SA-NAMESPACE
calico-node                                  calico-node                     ServiceAccount  kube-system
cluster-admin                                system:masters                  Group
```

## rbac-lookup

This project permits us to have a RBAC overview. It helps to answer the questions: Which Role has “nicola”?  All the users? all the group? To install the project:


```
kubectl krew install rbac-lookup
```
```
Updated the local copy of plugin index.
Installing plugin: rbac-lookup
Installed plugin: rbac-lookup
```

The official documentation is available on the !(http://github.com/reactiveops/rbac-lookup)[project Github repository]. An example:

```
kubectl-rbac_lookup nicola
```
```
SUBJECT   SCOPE                ROLE
nicola    project-production   Role/list-deployments
```

```
kubectl-rbac_lookup --kind user
```
```
SUBJECT                           SCOPE                ROLE
nicola                            project-production   Role/list-deployments
system:anonymous                  kube-public          Role/kubeadm:bootstrap-signer-clusterinfo
system:kube-controller-manager    cluster-wide         ClusterRole/system:kube-controller-manager
system:kube-controller-manager    kube-system          Role/extension-apiserver-authentication-reader
system:kube-controller-manager    kube-system          Role/system::leader-locking-kube-controller-manager
system:kube-proxy                 cluster-wide         ClusterRole/system:node-proxier
system:kube-scheduler             kube-system          Role/extension-apiserver-authentication-reader
system:kube-scheduler             kube-system          Role/system::leader-locking-kube-scheduler
system:kube-scheduler             cluster-wide         ClusterRole/system:kube-scheduler
system:kube-scheduler             cluster-wide         ClusterRole/system:volume-scheduler
```

```
kubectl-rbac_lookup --kind group
```
```
SUBJECT                                            SCOPE          ROLE
system:authenticated                               cluster-wide   ClusterRole/system:basic-user
system:authenticated                               cluster-wide   ClusterRole/system:discovery
system:authenticated                               cluster-wide   ClusterRole/system:public-info-viewer
system:bootstrappers:kubeadm:default-node-token    kube-system    Role/kube-proxy
system:bootstrappers:kubeadm:default-node-token    kube-system    Role/kubeadm:kubeadm-certs
system:bootstrappers:kubeadm:default-node-token    kube-system    Role/kubeadm:kubelet-config-1.16
system:bootstrappers:kubeadm:default-node-token    kube-system    Role/kubeadm:nodes-kubeadm-config
system:bootstrappers:kubeadm:default-node-token    cluster-wide   ClusterRole/system:node-bootstrapper
system:bootstrappers:kubeadm:default-node-token    cluster-wide   ClusterRole/system:certificates.k8s.io:certificatesigningrequests:nodeclient
system:masters                                     cluster-wide   ClusterRole/cluster-admin
system:nodes                                       kube-system    Role/kubeadm:kubelet-config-1.16
system:nodes                                       kube-system    Role/kubeadm:nodes-kubeadm-config
system:nodes                                       cluster-wide   ClusterRole/system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
system:unauthenticated                             cluster-wide   ClusterRole/system:public-info-viewer
```

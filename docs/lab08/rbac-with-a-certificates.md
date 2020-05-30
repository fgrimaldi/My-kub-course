## Users creation and authentication with X.509 client certificates

We mainly have two types of users: service accounts managed by Kubernetes and normal users. We will focus on normal users. Here is how the official documentation describes a normal user:

> Normal users are assumed to be managed by an outside, independent service. An admin distributing private keys, a user store like Keystone or Google Accounts, even a file with a list of usernames and passwords. In this regard, Kubernetes does not have objects which represent normal user accounts. Normal users cannot be added to a cluster through an API call.

They are multiple ways of managing normal users:

- Basic Authentication:
  - Pass a configuration with content like the following to API Server
  - password,username,uid,group
- X.509 client certificate
  - Create a user’s private key and a certificate signing request
  - Get it certified by a CA (Kubernetes CA) to have the user’s certificate
- Bearer Tokens (JSON Web Tokens)
  - OpenID Connect
  - On top of OAuth 2.0
  - Webhooks

For the purpose of this article we will use X.509 client certificates with OpenSSL for their simplicity. There are different steps for users creation. We will go step by step. You have to perform the actions as a user with cluster-admin credentials. These are the steps for user creation:


Create a user on the master machine then go into its home directory to perform the remaining steps.

```
useradd -m nicola && cd /home/nicola/
```

Create a private key:

```
openssl genrsa -out nicola.key 2048
```
```
Generating RSA private key, 2048 bit long modulus
................................................................................................+++
..........+++
e is 65537 (0x10001)
```

Create a certificate signing request (CSR). CN is the username and O the group. We can set permissions by group, which can simplify management if we have, for example, multiple users with the same authorizations.

```
# Without Group
openssl req -new -key nicola.key \
-out nicola.csr \
-subj "/CN=nicola"
```
Here you can see some example that you can use:
```
$group=gruppo1
# With a Group where $group is the group name
openssl req -new -key nicola.key \
-out nicola.csr \
-subj "/CN=nicola/O=$group"

#If the user has multiple groups
openssl req -new -key nicola.key \
-out nicola.csr \
-subj "/CN=nicola/O=$group1/O=$group2/O=$group3"
```

Sign the CSR with the Kubernetes CA. We have to use the CA cert and key which are normally in /etc/kubernetes/pki/. Our certificate will be valid for 3650 days.

```
openssl x509 -req -in nicola.csr \
-CA /etc/kubernetes/pki/ca.crt \
-CAkey /etc/kubernetes/pki/ca.key \
-CAcreateserial \
-out nicola.crt -days 3650
```
```
Signature ok
subject=/CN=nicola
Getting CA Private Key
```

Create a “.certs” directory where we are going to store the user public and private key.

```
mkdir .certs && mv nicola.crt nicola.key .certs
```

Create the user inside Kubernetes.

```
kubectl config set-credentials nicola \
--client-certificate=/home/nicola/.certs/nicola.crt \
--client-key=/home/nicola/.certs/nicola.key
```
```
User "nicola" set.
```

List actual contexts:
```
kubectl config get-contexts
```
```
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
```

Create a context for the user.

```
kubectl config set-context nicola-context \
--cluster=kubernetes --user=nicola
```
```
Context "nicola-context" created.
```

```
kubectl config use-context nicola-context
```
```
Switched to context "nicola-context".
```

```
kubectl get deploy
```
```
Error from server (Forbidden): deployments.apps is forbidden: User "nicola" cannot list resource "deployments" in API group "apps" in the namespace "default"

As you can see, you cannot list deployments. switch to the cluster-admin permissions context.
```

```
kubectl config use-context kubernetes-admin@kubernetes
```
```
Switched to context "kubernetes-admin@kubernetes".
```

```
kubectl create ns project-production
```
```
namespace/project-production created
```

File: /home/student/list-deployments-role.yaml

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: list-deployments
  namespace: project-production
rules:
  - apiGroups: [ apps, extensions ]
    resources: [ deployments ]
    verbs: [ get, list ]
```

To create them:
```

kubectl apply -f list-deployments-role.yaml
```
```
role.rbac.authorization.k8s.io/list-deployments created
```

## Bind Role

We are now going to bind list-deployments Role (View) to `nicola` as below:

File: /home/student/list-deployments-nicola-rolebinding.yaml


```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: list-deployments-nicola-rolebinding
  namespace: project-production  
subjects:
- kind: User
  name: nicola
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: list-deployments
  apiGroup: rbac.authorization.k8s.io
```

```
kubectl apply -f list-deployments-nicola-rolebinding.yaml
```
```
rolebinding.rbac.authorization.k8s.io/list-deployments-nicola-rolebinding created
```

```
kubectl config use-context nicola-context -n project-production
```
```
Switched to context "nicola-context".
```

```
kubectl get deployments

```
```
Error from server (Forbidden): deployments.apps is forbidden: User "nicola" cannot list resource "deployments" in API group "apps" in the namespace "default"
```

```
kubectl get deployments -n project-production
```
```
No resources found in project-production namespace.
```

```
kubectl config set-context --current --namespace project-production
```
```
Context "nicola-context" modified.
```

```
kubectl get deployment
```
```
No resources found in project-production namespace.
```

```
kubectl create deploy nginx --image=nginx
```
```
Error from server (Forbidden): deployments.apps is forbidden: User "nicola" cannot create resource "deployments" in API group "apps" in the namespace "project-production"
```

```
kubectl auth can-i list pods
```

```
no
```

```
kubectl auth can-i list deployments
```
```
yes
```

```
kubectl config use-context kubernetes-admin@kubernetes
```
```
Switched to context "kubernetes-admin@kubernetes".
```

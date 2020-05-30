# Grow the Cluster

Open another terminal and connect into a your worker node. Install Docker and Kubernetes software. These are the many, but not all, of the steps we did on the master node.

The book will use the worker prompt for the node being added to help keep track of the proper node for each command. Note that the prompt indicates both the user and system upon which run the command.

Connect to worker node:


Become root and update and upgrade the system. Answer any questions to use the defaults.

```
student@worker:~$ sudo -i  
root@worker:~#
```

From your prompt you can understand if the command should be launched as priviledged or not.

If you see $ that means this is a normal user.
If you see a # that means this is a root account.

Now set hosts file:
```console
root@worker:~# ifconfig ens160 | grep inet
        inet 10.10.98.11  netmask 255.255.255.0  broadcast 10.10.98.255
        inet6 fe80::250:56ff:fe8a:80e7  prefixlen 64  scopeid 0x20<link>
```

In this case the worker IP address is 10.10.98.11

Now edit the file */etc/hosts* accordingly:

```console
root@worker:~# vi /etc/hosts
```

It should look like this:

```vim
127.0.0.1       localhost
10.10.98.11     worker
```

Try to ping, the result should be the correct IP:

```console
root@worker:~# ping worker
PING worker (10.10.98.11) 56(84) bytes of data.
```

Update the OS

```console
root@worker:~# apt-get update && apt-get upgrade -y  
<output_omitted>
```

The main choices for a container environment are Docker and cri-o. We will user Docker for class, as cri-o requires a fair amount of extra work to enable for Kubernetes. As cri-o is open source the community seems to be heading towards its use.

We will follow the official guide of K8s

https://kubernetes.io/docs/setup/production-environment/container-runtimes/

We should remove older versions of Docker.

```console
root@worker:~# apt-get remove docker docker-engine docker.io containerd runc
```

```console
root@worker:~# apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    jq \
    gnupg-agent \
    software-properties-common
```
```
<output_omitted>  
```

Add Docker’s official GPG key:

```console
root@worker:~# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```
```console
OK
```

Verify that you now have the key with the fingerprint 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88, by searching for the last 8 characters of the fingerprint.

```console
root@worker:~# sudo apt-key fingerprint 0EBFCD88
```
```console
pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]```
```

Add repository .
Note: The lsb_release -cs sub-command below returns the name of your Ubuntu distribution, such as xenial. Sometimes, in a distribution like Linux Mint, you might need to change $(lsb_release -cs) to your parent Ubuntu distribution. For example, if you are using Linux Mint Tessa, you could use bionic. Docker does not offer any guarantees on untested and unsupported Ubuntu distributions.

```console
root@worker:~# lsb_release -cs
bionic
```
```console
root@worker:~# add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
```

Update the apt package index.

```console
root@worker:~# apt-get update
```

Create Docker folder

```console
root@worker:~# mkdir /etc/docker
```

Configure Docker daemon to use native cgroup driver systemd

```console
root@worker:~# cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
```

Install the latest version of Docker CE and containerd, or go to the next step to install a specific version: `5:18.09.9~3-0~ubuntu-xenial`

```console
root@worker:~# apt-get install -y docker-ce=5:18.09.9~3-0~ubuntu-xenial docker-ce-cli=5:18.09.9~3-0~ubuntu-xenial containerd.io
```

Add your user to the docker group

```console
root@worker:~# usermod -aG docker student
```

Most current Linux distributions (RHEL, CentOS, Fedora, Ubuntu 16.04 and higher) use systemd to manage which services start when the system boots. Ubuntu 14.10 and below use upstart.
```console
root@worker:~# systemctl enable docker
```
```console
Synchronizing state of docker.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable docker
```
Let's start Docker
```console
root@worker:~# systemctl start docker
```

Let's check Docker status
```console
root@worker:~# systemctl status docker
```
```console
● docker.service - Docker Application Container Engine
   Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2019-07-14 19:53:19 CEST; 45s ago
     Docs: https://docs.docker.com
```
Service must be active (running).

Try to run the command *docker info*

```console
root@worker:~# docker info
```

Check if native cgroup driver are correct:
```console
root@worker:~# docker info | grep "Cgroup Driver:"
```
```console
Cgroup Driver: systemd
```

Driver must be Systemd. If not try to restart docker.

```console
root@worker:~# systemctl restart docker
```

Disable swap:

```console
root@worker:~# swapoff -av
```

Now edit the file */etc/fstab*:

```console
root@worker:~# vi /etc/fstab
```

Remove the following line (can be different), you are removing swap volume:

```console
/dev/mapper/master--vg-swap_1 none            swap    sw              0       0
```

Let's start by adding the Kubernetes signing key:

```console
root@worker:~#  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -  
```
```console
OK
```
Add new repo for K8s. You could also get a tar file or use code from GitHub. Create the file and add an entry for the main repo for your distribution.

NOTE: At the time of writing only Ubuntu 16.04 Xenial Kubernetes repository is available. Replace the below xenial with bionic codename once the Ubuntu 18.04 Kubernetes repository becomes available.
https://kubernetes.io/docs/setup/independent/install-kubeadm/

```console
root@worker:~# apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
```
```console
<output_omitted>
```

```console
root@worker:~# apt-get update
```

Install the software. There are regular releases the newest of which can be used by omitting the equal sign and version information on the command line. Historically new version have lots of changes and a good chance of a bug or five.

```console
root@worker:~# apt-get install -y kubeadm=1.15.4-00 kubelet=1.15.4-00 kubectl=1.15.4-00
```
```console
Setting up conntrack (1:1.4.4+snapshot20161117-6ubuntu2) ...
Setting up kubernetes-cni (0.7.5-00) ...
Setting up cri-tools (1.13.0-00) ...
Setting up socat (1.7.3.2-2ubuntu2) ...
Setting up kubelet (1.15.4-00) ...
Created symlink /etc/systemd/system/multi-user.target.wants/kubelet.service → /lib/systemd/system/kubelet.service.
Setting up kubectl (1.15.4-00) ...
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
Setting up kubeadm (1.15.4-00) ...
```

Please note: the output lists several commands which following commands will complete.

Find the IP address of your master server. The interface name will be different depending on where the node is running. Currently inside of VM the primary interface for this node type is ens160. Your interfaces names may be different. From the output we know our master node IP is 10.10.98.10.

```console
student@master:~$ ip addr show ens160 | grep inet
```
```console
    inet 10.10.98.10/24 brd 10.10.98.255 scope global ens160
    inet6 fe80::250:56ff:fe8a:503e/64 scope link
```

At this point we could copy and paste the join command from the master node. That command only works for 24 hours, so we will build our own join should we want to add compute nodes in the future. Find the token on the master node. The token lasts 24 hours by default. If it has been longer, and no token is present you can generate a new one with the sudo kubeadm token create command, seen in the following command.

```console
student@master:~$ sudo kubeadm token list  
```
```console
TOKEN                     TTL       EXPIRES                     USAGES                   DESCRIPTION                                                EXTRA GROUPS
pgopmm.l7br35wtrp1u77m0   22h       2019-07-15T18:20:07+02:00   authentication,signing   The default bootstrap token generated by 'kubeadm init'.   system:bootstrappers:kubeadm:default-node-token
```

Only if the token has expired, you can create a new token, to use as part of the join command.

```console
student@master:~$ sudo kubeadm token create
```
```console
u3a427.b65xcvlbn8s6dja6
```

Starting in v1.9 you should create and use a Discovery Token CA Cert Hash created from the master to ensure the node joins the cluster in a secure manner. Run this on the master node or wherever you have a copy of the CA file. You will get a long string as output.

```console
student@master:~$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'  
```
```console
ed4a67aca3ef58114483b97d112ea223e1335e1a5f7197a22c9f41e6b4cc53fd
```

Use the token and hash, in this case as sha256:<hash> to join the cluster from the second/worker node. Use the private IP address of the master server and port 6443. The output of the kubeadm init on the master also has an example to use, should it still be available.

```console
root@worker:~# kubeadm join --token u3a427.b65xcvlbn8s6dja6 10.10.98.10:6443 --discovery-token-ca-cert-hash sha256:ed4a67aca3ef58114483b97d112ea223e1335e1a5f7197a22c9f41e6b4cc53fd | tee /root/kubeadm-join.out
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.15" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Activating the kubelet service
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

Try to run the kubectl command on the secondary system. It should fail. You do not have the cluster or authentication keys in your local .kube/config file.

```console
root@worker:~# kubectl get nodes
```
```console
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

On Master get nodes list

```console
student@master:~$ kubectl get nodes
```
```console
NAME     STATUS   ROLES    AGE    VERSION
master   Ready    master   105m   v1.15.0
worker   Ready    <none>   57s    v1.15.0
```

Now you have 2 nodes.

[Back](lab01.md)

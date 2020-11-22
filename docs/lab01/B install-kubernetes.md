# Install Kubernetes

## Overview

There are several Kubernetes installation tools provided by various vendors. In this lab we will learn to use kubeadm. As a community-supported independent tool, it is planned to become the primary manner to build a Kubernetes cluster.

The labs were written using Ubuntu instances running on cloud. They have been written to be vendor-agnostic so could run on AWS, local hardware, or inside of virtualization system to give you the most flexibility and options. Each platform will have different access methods and considerations. As of v1.15 the minimum (as in barely works) size for VM is 4vCPU/1-5GB minimal OS for master and 2vCPU/1GB-5GB minimal OS for worker node.

If using your own equipment you will have to disable swap on every node. There may be other requirements which will be shown as warnings or errors when using the kubeadm command. While most commands are run as a regular user, there are some which require root privilege. Please configure sudo access as shown in a previous lab. You If you are accessing the nodes remotely, such as with GCP or AWS, you will need to use an SSH client such as a local terminal or PuTTY if not using Linux or a Mac. You can download PuTTY from www.putty.org. You would also require a .pem or .ppk file to access the nodes. Each cloud provider will have a process to download or create this file. If attending in-person instructor led training the file will be made available during class.

In the following exercise we will install Kubernetes on a single node then grow the cluster, adding more compute resources. Both nodes used are the same size, providing 4 vCPUs and 7.5G of memory. Smaller nodes could be used, but would run slower.

Various exercises will use YAML files, which are included in the text. You are encouraged to write the files when possible, as the syntax of YAML has white space indentation requirements that are important to learn. An important note, do not use tabs in your YAML files, white space only. Indentation matters.

If using a PDF the use of copy and paste often does not paste the single quote correctly. It pastes as a back-quote instead. You will need to modify it by hand. The files have also been made available as a compressed tar file.

## Access on VM
You can access using labs webpage:

https://labs.desotech.it

Username: provided by your instructor

Password: provided by your instructor



Access on Master VM

Username: student

Password: DesotechKube1!


## Install Kubernetes

Connect to master node:


Become root and update and upgrade the system. Answer any questions to use the defaults.

```console
student@master:~$ sudo -i  
root@master:~#
```

From your prompt you can understand if the command should be launched as priviledged or not.

If you see $ that means this is a normal user.

If you see a # that means this is a root account.


Now we're going to set hosts file.

Use `ifconfig` to see the master IP address:

```console
root@master:~# ifconfig ens160 | grep inet
        inet 10.10.98.10  netmask 255.255.255.0  broadcast 10.10.98.255
        inet6 fe80::250:56ff:fe8a:503e  prefixlen 64  scopeid 0x20<link>
```

In this case the master node IP address is 10.10.98.10.

Now edit the file */etc/hosts* accordingly:

```console
root@master:~# vi /etc/hosts
```

It should look like this:

```vim
127.0.0.1       localhost
10.10.98.10     master
```

Try to ping, the result should be the correct IP:

```console
root@master:~# ping master
PING master10.10.98.10 (10.10.98.10) 56(84) bytes of data.
```

```console
root@master:~# apt-get update && apt-get upgrade -y  
<output_omitted>
```

The main choices for a container environment are Docker and cri-o. We will user Docker for class, as cri-o requires a fair amount of extra work to enable for Kubernetes. As cri-o is open source the community seems to be heading towards its use.

We will follow the official guide of K8s

https://kubernetes.io/docs/setup/production-environment/container-runtimes/

We should remove older versions of Docker.

```console
root@master:~# apt-get remove docker docker-engine docker.io containerd runc
```

```console
root@master:~# apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    jq \
    gnupg-agent \
    software-properties-common
```
```console
<output_omitted>  
```

Add Docker’s official GPG key:

```console
root@master:~# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```
```console
OK
```

Verify that you now have the key with the fingerprint 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88, by searching for the last 8 characters of the fingerprint.

```console
root@master:~# sudo apt-key fingerprint 0EBFCD88
```
```console
pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]```
```

Add repository.
Note: The lsb_release -cs sub-command below returns the name of your Ubuntu distribution, such as xenial. Sometimes, in a distribution like Linux Mint, you might need to change $(lsb_release -cs) to your parent Ubuntu distribution. For example, if you are using Linux Mint Tessa, you could use bionic. Docker does not offer any guarantees on untested and unsupported Ubuntu distributions.

```console
root@master:~# lsb_release -cs
bionic
```

```console
root@master:~# add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
```

Update the apt package index:

```console
root@master:~# apt-get update
```

Create Docker folder:

```console
root@master:~# mkdir /etc/docker
```

Configure Docker daemon to use native cgroup driver systemd:

```console
root@master:~# cat > /etc/docker/daemon.json <<EOF
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

```console
root@master:~# apt-cache madison docker-ce
```

```console
 docker-ce | 5:19.03.3~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:19.03.2~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:19.03.1~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:19.03.0~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.9~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.8~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.7~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.6~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.5~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.4~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.3~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.2~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.1~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 5:18.09.0~3-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 18.06.3~ce~3-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 18.06.2~ce~3-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 18.06.1~ce~3-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 18.06.0~ce~3-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 18.03.1~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 18.03.0~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.12.1~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.12.0~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.09.1~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.09.0~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.06.2~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.06.1~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.06.0~ce-0~ubuntu | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.03.3~ce-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.03.2~ce-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.03.1~ce-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
 docker-ce | 17.03.0~ce-0~ubuntu-xenial | https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
```

Read the version of docker-ce 18.09, in the example the last version are:

Install the latest version of Docker CE and containerd, or go to the next step to install a specific version: `5:18.09.9~3-0~ubuntu-xenial`

```console
root@master:~# apt-get install -y docker-ce=5:18.09.9~3-0~ubuntu-xenial docker-ce-cli=5:18.09.9~3-0~ubuntu-xenial containerd.io
```


Add your user to the docker group:

```console
root@master:~# usermod -aG docker  student
```

Most current Linux distributions (RHEL, CentOS, Fedora, Ubuntu 16.04 and higher) use systemd to manage which services start when the system boots. Ubuntu 14.10 and below use upstart.

```console
root@master:~# systemctl enable docker
```

```console
Synchronizing state of docker.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable docker
```

Let's start Docker:

```console
root@master:~# systemctl start docker
```

```console
root@master:~# systemctl status docker
```

```console
● docker.service - Docker Application Container Engine
   Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2019-07-14 17:14:17 CEST; 3min 12s ago
     Docs: https://docs.docker.com
```

Service must be active (running).

Try to run the command *docker info*:

```console
root@master:~# docker info
```

Check if native cgroup driver are correct:

```console
root@master:~# docker info | grep "Cgroup Driver:"
```

```console
Cgroup Driver: systemd
```

Driver must be `Systemd`. If not try to restart docker.

Disable swap:

```console
root@master:~# swapoff -av
```

Edit file /etc/fstab

Remove the following line, can be different, you are removing swap volume:

```console
/dev/mapper/master--vg-swap_1 none            swap    sw              0       0
```

Let's start by adding the Kubernetes signing key:

```console
root@master:~#  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -  
```

```console
OK
```

Add new repo for K8s. You could also get a tar file or use code from GitHub. Create the file and add an entry for the main repo for your distribution.

NOTE: At the time of writing only Ubuntu 16.04 Xenial Kubernetes repository is available. Replace the below xenial with bionic codename once the Ubuntu 18.04 Kubernetes repository becomes available.
https://kubernetes.io/docs/setup/independent/install-kubeadm/

```console
root@master:~# apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
```

```console
<output_omitted>
```

```console
root@master:~# apt-get update
```

Install the software. There are regular releases the newest of which can be used by omitting the equal sign and version information on the command line. Historically new version have lots of changes and a good chance of a bug or five.

```console
root@master:~# apt-get install -y kubeadm=1.16.3-00 kubelet=1.16.3-00 kubectl=1.16.3-00  
```

```console
Setting up conntrack (1:1.4.4+snapshot20161117-6ubuntu2) ...
Setting up kubernetes-cni (0.7.5-00) ...
Setting up cri-tools (1.13.0-00) ...
Setting up socat (1.7.3.2-2ubuntu2) ...
Setting up kubelet (1.15.0-00) ...
Created symlink /etc/systemd/system/multi-user.target.wants/kubelet.service → /lib/systemd/system/kubelet.service.
Setting up kubectl (1.15.0-00) ...
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
Setting up kubeadm (1.15.0-00) ...
```

Please note: the output lists several commands which following commands will complete.

Pull Kubernetes images from Google repository:

```console
root@master:~# kubeadm config images pull
```

```console
[config/images] Pulled k8s.gcr.io/kube-apiserver:v1.15.4
[config/images] Pulled k8s.gcr.io/kube-controller-manager:v1.15.4
[config/images] Pulled k8s.gcr.io/kube-scheduler:v1.15.4
[config/images] Pulled k8s.gcr.io/kube-proxy:v1.15.4
[config/images] Pulled k8s.gcr.io/pause:3.1
[config/images] Pulled k8s.gcr.io/etcd:3.3.10
[config/images] Pulled k8s.gcr.io/coredns:1.3.1
```

We can deploy our first k8s cluster using kubeadm

Fortunately, Kubernetes has a component called the Kubelet which manages containers running on a single host. It uses the API server but it doesn't depend on it so we can actually use the Kubelet to manage the control plane components. This is exactly what kubeadm sets us up to do. Let's look at what happens when we run kubeadm.

```console
root@controller01:~# kubeadm init --kubernetes-version 1.16.3 --pod-network-cidr 192.168.0.0/16 | tee /root/kubeadm-init.out
```

```console
[init] Using Kubernetes version: v1.15.4-
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"


<output-omitted>  


Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.10.98.10:6443 --token pgopmm.l7br35wtrp1u77m0 \
    --discovery-token-ca-cert-hash sha256:ed4a67aca3ef58114483b97d112ea223e1335e1a5f7197a22c9f41e6b4cc53fd
```

Now we can enable our kubelet service:

```console
root@master:~# systemctl enable kubelet.service
```

And start your kubelet service:

```console
root@master:~# systemctl start kubelet
```

Check the services:

```console
root@master:~# systemctl status kubelet
```

```console
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: active (running) since Sun 2019-07-14 17:37:20 CEST; 30min ago
```

The service must be active (running).

[Back](lab01.md)



root@aruba-k8s-master01:~# kubeadm init --pod-network-cidr=192.168.0.0/16 --control-plane-endpoint "10.10.99.100:6443" --upload-certs



Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join 10.10.99.100:6443 --token tp66b0.sejqnrxlvbsauscf \
    --discovery-token-ca-cert-hash sha256:d85a020cc6372f729722800917cbb5bb8698c2b737574de1d04db81560ce3419 \
    --control-plane --certificate-key a6d652670167511e58fe40752862aea48247358ff71fa9a2edab0f9ca83dd8f6

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.10.99.100:6443 --token tp66b0.sejqnrxlvbsauscf \
    --discovery-token-ca-cert-hash sha256:d85a020cc6372f729722800917cbb5bb8698c2b737574de1d04db81560ce3419




root@aruba-k8s-master01:~# kubeadm init phase upload-certs --upload-certs
[upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[upload-certs] Using certificate key:
86f75657eca2f8a7f0c949dab32628a4d9989ebddc7c5a5396d4cf909d32b17b


In the master node, edit the following config file

nano /etc/kubernetes/manifests/kube-apiserver.yaml
add the following configuration into the file, for example I want to extend the port from 30000 into 50000

spec:
  containers:
  - command:
    - kube-apiserver
    ...
    - --service-node-port-range=30000-50000
    ...
restart kubelet

systemctl restart kubelet








kubeadm join 10.10.99.100:6443 --token tp66b0.sejqnrxlvbsauscf \
     --discovery-token-ca-cert-hash sha256:d85a020cc6372f729722800917cbb5bb8698c2b737574de1d04db81560ce3419 \
     --control-plane --certificate-key 86f75657eca2f8a7f0c949dab32628a4d9989ebddc7c5a5396d4cf909d32b17b


╰─ kubectl get nodes                                                         ─╯
NAME                 STATUS     ROLES    AGE     VERSION
aruba-k8s-master01   NotReady   master   10m     v1.16.3
aruba-k8s-master02   NotReady   master   2m32s   v1.16.3
aruba-k8s-master03   NotReady   master   22s     v1.16.3



kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml


╰─ kubectl get nodes                                                         ─╯
NAME                 STATUS   ROLES    AGE     VERSION
aruba-k8s-master01   Ready    master   14m     v1.16.3
aruba-k8s-master02   Ready    master   6m4s    v1.16.3
aruba-k8s-master03   Ready    master   3m54s   v1.16.3



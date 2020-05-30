
# Creating a NFS Server

We will first deploy an NFS server. 

Install the software on your master node.

```
$ sudo apt-get update && sudo apt-get install -y nfs-kernel-server  
<output_omitted>
```

Make and populate a directory to be shared. Also give it similar permissions to /tmp/

```
$ sudo mkdir /opt/nfs
```

```
$ sudo chmod 1777 /opt/nfs/
```
```
$ sudo bash -c 'echo test > /opt/nfs/file.txt'
```

Edit the NFS server file to share out the newly created directory. In this case we will share the directory with all. You can always snoop to see the inbound request in a later step and update the file to be more narrow.


```
$ sudo vim /etc/exports
```


File: /etc/exports


```
/opt/nfs/ *(rw,sync,no_root_squash,subtree_check)
```


Cause /etc/exports to be re-read:


```
$ sudo exportfs -ra
```
Please verify your NFS export:
```  
$ sudo hostname -i
10.10.98.129
```
```
$ sudo showmount -e 10.10.98.129
Export list for 10.10.98.129:
/opt/nfs *
```
Now test by mounting the resource from your workers node for check if NFS are working.

```
$ sudo apt-get -y install nfs-common  
<output_omitted>  
```
Check if showmount can visualize your NFS export on the master node.
```
$ sudo showmount -e 10.10.98.129
Export list for 10.10.98.129:
/opt/nfs *
```
Create a test-nfs folder

```
$ sudo mkdir /test-nfs
```


```
$ sudo mount 10.10.98.129:/opt/nfs /test-nfs/
```

```
$ sudo ls -l /test-nfs/
total 4
-rw-r--r-- 1 root root 5 Nov 23 11:39 file.txt
```

Now you can see the file and you can unmount NFS share from your worker.
```
$ sudo umount /test-nfs/
```

Repeat the procedure on all worker nodes.


[Back](lab07.md)

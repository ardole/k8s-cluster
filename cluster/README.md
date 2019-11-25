# Setup K8S Cluster on local environment

Using:
- Virtualbox
- Vagrant

## What you need

Sorry for guys working in any ESN company providing 2vCPU and 8go RAM, you will need more :grin:

- At least 8vCPU
- At least 16go RAM
- Disk > 256go

And Vagrant / Virtualbox installed. https://www.vagrantup.com/downloads.html 

**To be ROOT**

## Setup virtual machines

You can use followings templates:
- [K8S Master VM](vagrant/master/Vagrantfile)
- [K8S Node VM](vagrant/master/Vagrantfile)

You can use a simple script to start all VM easily and then SSH to the master:
```bat
cd vagrant

cd master
vagrant up

cd ../node1
vagrant up

cd ../master
vagrant ssh
```

## On each VM

### Prepare network

- Without DNS, manual setup hosts : vi /etc/hosts.
```
172.28.128.8 k8s-master  
172.28.128.9 k8s-node1 
172.28.128.10 k8s-node2 
```

- Set SELinux in permissive mode (effectively disabling it).
```
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
modprobe br_netfilter
```

- Update sysctl config.
```
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
```

- Deactivate SWAP.
```
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### Setup Docker

- Follow official doc:
```
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install --assumeyes docker-ce-17.09.*
systemctl daemon-reload
systemctl start docker
systemctl enable docker
```

### Install Kubelet and Kubadm

- Add Yum repository.
```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
```

- Add and enable Kubelet service.
```
yum install -y kubelet kubeadm --disableexcludes=kubernetes
systemctl enable kubelet
```

- Pull images for initialization.
```
kubeadm config images pull
```

## On the master only

- Choose a futur pod network add-on https://kubernetes.io/docs/concepts/cluster-administration/addons/.
Here we choose *Flannel* as it works well with Virtualbox network.
So we need to add option *--pod-network-cidr=10.244.0.0/16* at kubeadm initialization.

- Start initialization. Please replace apiserver-advertise-address by master's network IP.
```
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.0.2.15
```

- If success, don't forget to copy kubeadm join command line given in output command.

- Validate master configuration.
```
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

- Finally, install the pod network you choose before.
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

- Wait your master to be READY.
```
kubectl get nodes
```
- You can get a little more details on pods initialization.
```
kubectl get pods --all-namespaces
```

## On each nodes

- Join the cluster with the command *kubeadm join* you copy before.
```
kubeadm join 10.0.2.15:6443 --token abc123.bfl34rze70jddcsg \
    --discovery-token-ca-cert-hash sha256:blablabla
```

- Go back to the master and check that your nodes comes and are READY !

```
kubectl get nodes
```

## Setup Kubernetes dashboard

- In order to setup dashboard you need to run on the master:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml
```

- When you need it, simply start it:
```
kubectl proxy --address=0.0.0.0
```
Then dashboard will be accessible on http://localhost:8081/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ from your host (because 8001 port is forwarded to 8081 in Vagrant config see [Vagrantfile](vagrant/master/Vagrantfile)

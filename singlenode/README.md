# Setup K8S Single Node on local environment

Using:
- Virtualbox
- Vagrant

## What you need

Sorry for guys working in any ESN company providing 2vCPU and 8go RAM, you will need more :grin:

- At least 4vCPU
- At least 8go RAM
- Disk > 128go

And Vagrant / Virtualbox installed. https://www.vagrantup.com/downloads.html 

**To be ROOT**

## Setup a virtual machine

In this example, CentOS 7.

## Prepare network

- Without DNS, manual setup hosts : vi /etc/hosts

```
172.28.128.8 k8s-master  
```

- Set SELinux in permissive mode (effectively disabling it).
```
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
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

## Setup Docker

- Follow official doc:
```
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install --assumeyes docker-ce-17.09.*
systemctl daemon-reload
systemctl start docker
systemctl enable docker
```

## Install Kubelet and Kubadm

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
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet
```

- Pull images for initialization.
```
kubeadm config images pull
```

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

- Wait your node to be READY.

```
kubectl get nodes
```

- Activate scheduling of pods on the control-plane node

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

## WIP

### Install Ingress Controller


```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
kubectl get pods --all-namespaces -l app.kubernetes.io/name=ingress-nginx --watch
```

### Install MetalLB

```
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
```

- config.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
      - name: my-ip-space
        protocol: layer2
        addresses:
          - 172.28.128.100-172.28.128.140
```

```
kubectl apply -f config.yml
```

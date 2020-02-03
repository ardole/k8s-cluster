#!/bin/bash

set -e

# Global configuration

sudo bash -c 'cat > /etc/hosts <<EOF
127.0.0.1		localhost
192.168.48.141	k8s-1
192.168.48.142	k8s-2
192.168.48.143	k8s-3
EOF'

# Install Docker

sudo yum install -y apt-transport-https ca-certificates curl software-properties-common
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce-19.03.5
sudo mkdir -p /etc/docker
sudo bash -c 'cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF'
sudo systemctl daemon-reload
sudo systemctl enable docker.service
sudo systemctl restart docker

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Run prerequisites
sudo bash -c 'cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF'
sudo sysctl --system
sudo sysctl -p
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Install Kubernetes
sudo bash -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF'

sudo yum install -y kubelet-1.17.2 kubeadm-1.17.2 kubectl-1.17.2 --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# Initialize K8S
sudo kubeadm config images pull
sudo kubeadm init --token vag3nt.nos3curebutlocal --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.48.141 > kubeinit.log
sudo kubectl taint nodes --all node-role.kubernetes.io/master-

# Move K8S config to vagrant user and create K8S
mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
# Install CNI : Flannel
su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"

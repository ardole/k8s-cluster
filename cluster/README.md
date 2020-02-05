# Setup K8S Cluster on local environment (cluster)

Using:
- Virtualbox
- Vagrant

## What you need

Vagrant and Virtualbox installed.
- https://www.vagrantup.com/downloads.html 
- https://www.virtualbox.org/wiki/Downloads

Sorry for guys working in ESN company providing 1vCPU and 4go RAM, you will need more :grin:

- At least 4vCPU
- At least 8go RAM
- Disk > 128go


## Setup Cluster

You will use this template:
- [K8S Cluster](vagrant/Vagrantfile)
You can modify if needed servers settings:
- [servers.json](vagrant/servers.json)

```
cd vagrant
vagrant up
```
## Check installation 

- SSH connexion to control machine

```
cd vagrant
vagrant ssh k8s-1
```

- Check nodes

```console
[vagrant@k8s-1 ~]$ kubectl get nodes
NAME    STATUS   ROLES    AGE   VERSION
k8s-1   Ready    master   66m   v1.17.2
k8s-2   Ready    <none>   61m   v1.17.2
k8s-3   Ready    <none>   55m   v1.17.2
```

## More about this cluster

### Components

- Control machine is **k8s-1**
- Docker is installed, with systemd
- CNI used is Calico

### About Calico

Some difficulties with Flannel and Virtualbox. Calico works well.

:warning: Default CIDR 192.168.0.0/16 create some conflicts with Virtualbox, 
So **kubeadm init** is done with option **--pod-network-cidr=172.16.0.0/16**

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

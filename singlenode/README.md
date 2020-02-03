# Setup K8S Single Node on local environment

Using:
- Virtualbox
- Vagrant

## What you need

Sorry for guys working in any ESN company providing 1vCPU and 4go RAM, you will need more :grin:

- At least 4vCPU
- At least 8go RAM
- Disk > 128go

And Vagrant / Virtualbox installed. https://www.vagrantup.com/downloads.html 

## Setup Cluster

You can use following template:
- [K8S Cluster](vagrant/Vagrantfile)
Modify servers settings:
- [servers.json](vagrant/servers.json)

### Start cluster

```bat
cd vagrant
vagrant up
```

### Check installation 

- SSH connexion to control machine

```
cd vagrant
vagrant ssh k8s-1
```

- Check node

```
[vagrant@k8s-1 ~]$ kubectl get nodes
NAME    STATUS   ROLES    AGE   VERSION
k8s-1   Ready    master   66m   v1.17.2

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

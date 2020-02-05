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

- Check that all kube-system pods are running (coredns, calico, kube-proxy...) 

```console
[vagrant@k8s-1 ~]$ kubectl get pods -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-5b644bc49c-csxh9   1/1     Running   1          126m
calico-node-jmfx2                          1/1     Running   1          120m
calico-node-vw9sg                          1/1     Running   1          126m
coredns-6955765f44-6mtsz                   1/1     Running   1          126m
coredns-6955765f44-zlfbz                   1/1     Running   1          126m
etcd-k8s-1                                 1/1     Running   1          126m
kube-apiserver-k8s-1                       1/1     Running   1          126m
kube-controller-manager-k8s-1              1/1     Running   1          126m
kube-proxy-lmczw                           1/1     Running   1          120m
kube-proxy-qrsw6                           1/1     Running   1          126m
kube-scheduler-k8s-1                       1/1     Running   1          126m
```

## Post installation steps

If you want to use and test Ingress resources, 
you will need to update the /etc/hosts on master.

```console
[vagrant@k8s-1 ~]$ kubectl get ing
NAME          HOSTS          ADDRESS        PORTS   AGE
my-ingress    mywebserver    10.100.71.58   80      103m
```

```console
[vagrant@k8s-1 ~]$ cat /etc/hosts
127.0.0.1       localhost
10.100.71.58    mywebserver
192.168.50.10   k8s-1
192.168.50.11   k8s-2
192.168.50.12   k8s-3
```

## More about this cluster

### Components

- Control machine is **k8s-1**
- Docker is installed, with systemd
- CNI used is Calico
- Nginx Ingress
- A bare metal load-balancer : MetalLB

### About Calico

Some difficulties with Flannel and Virtualbox. Calico works well.

:warning: Default CIDR 192.168.0.0/16 create some conflicts with Virtualbox, 
So **kubeadm init** is done with option **--pod-network-cidr=172.16.0.0/16**

### About MetalLB

Kubernetes does not offer an implementation of network load-balancers (Services of type LoadBalancer) for bare metal clusters.
If you’re not running on a supported IaaS platform (GCP, AWS, Azure…), LoadBalancers will remain in the “pending” state indefinitely when created.

```console
[root@localhost temp]# kubectl get services
NAME       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
my-nginx   LoadBalancer   10.111.43.88   <pending>     80:31730/TCP     22m
```

With MetalLB, it works ! https://metallb.universe.tf/

Range IPs for MetalLB is configured 192.168.50.240-192.168.50.250. See [vagrant/install-k8s-master.sh](vagrant/install-k8s-master.sh) 

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

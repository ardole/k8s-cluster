# Setup K8S on local environment

Using:
- Virtualbox
- Vagrant
- Minikube

## Prerequisites

- At least 4vCPU
- At least 8go RAM
- Disk > 128go

Any local machine or a virtual box maybe with Vagrant / Virtualbox.

This guide works with a VM CentOS 7. But it should be easy to adapt.

## Installation

Install Minikube by following the official documentation:
https://kubernetes.io/docs/setup/learning-environment/minikube/

### Install Docker

```shell
sudo su -
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io
```

### Install Kubectl

```shell
sudo su -
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubectl
exit
```

### Install Minikube

```shell
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube
sudo mkdir -p /usr/local/bin/
sudo install minikube /usr/local/bin/
```

### Create your local K8S node

- Start the cluster

```
minikube start --vm-driver=none
```

- Wait for your single node to be ready

```console
[root@localhost ~]# kubectl get nodes --all-namespaces
NAME       STATUS   ROLES    AGE   VERSION
minikube   Ready    master   43h   v1.16.2
```

- Check that everything is working with app **hello-minikube**

```console
[root@localhost ~]# kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.10
minikube service hello-minikube --urldeployment.apps/hello-minikube created
[root@localhost ~]# kubectl expose deployment hello-minikube --type=NodePort --port=8080
service/hello-minikube exposed
[root@localhost ~]# kubectl get pod
NAME                              READY   STATUS        RESTARTS   AGE
hello-minikube-797f975945-v5l2j   1/1     Running       0          8s
[root@localhost ~]# minikube service hello-minikube --url
http://10.0.2.15:30392
[root@localhost ~]# curl http://10.0.2.15:30392

Hostname: hello-minikube-797f975945-v5l2j

Pod Information:
        -no pod information available-

Server values:
        server_version=nginx: 1.13.3 - lua: 10008

Request Information:
        client_address=172.17.0.1
        method=GET
        real path=/
        query=
        request_version=1.1
        request_scheme=http
        request_uri=http://10.0.2.15:8080/

Request Headers:
        accept=*/*
        host=10.0.2.15:30392
        user-agent=curl/7.29.0

Request Body:
        -no body in request-
```

- Clean all

```compose
kubectl delete services hello-minikube
kubectl delete deployment hello-minikube
```

- Stop Minikube

```
minikube stop
```

- Delete Minikube installation

```
minikube delete
```

## Enable LoadBalancer

### External-IP &laquo; pending &raquo;

As you are running on a bare metal server, you can't use **LoadBalancer** service by default.

- Create a simple *nginx* deployment.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.8
        ports:
        - containerPort: 80
```

- Create a service with type = LoadBalancer.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  type: LoadBalancer
```

- Apply this configuration with *kubectl apply* and then see what happen onto your service.

```console
[root@localhost temp]# kubectl get services
NAME       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
my-nginx   LoadBalancer   10.111.43.88   <pending>     80:31730/TCP     22m
```

External IP is still &laquo; pending &raquo;. So, you can't use and test Ingress controllers !

### Ingress

First, enable Ingress Controller https://kubernetes.github.io/ingress-nginx/deploy/#minikube

```
minikube addons enable ingress
```
 
### MetalLB

MetalLB offers a nice Network LB implementation, that you can use to create external services on bare metal !
https://metallb.universe.tf/

- Installation

```
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
```

- Create a simple configuration *config.yml*, with your local IPs adresses that should be assign to external services.
For me I use 172.28.128.100-172.28.128.140 (I choose eth1 addresses but you can choose eth0).

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

- Enable local configuration

```
kubectl apply -f config.yml
```

- Then, see what happen onto your service:

```console
[root@localhost temp]# kubectl get services
NAME       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
my-nginx   LoadBalancer   10.110.94.235   172.28.128.101   80:31930/TCP     2m25s
```

Normally, an EXTERNAL-IP should has been assigned !!! You have an external access !!

```
curl http://172.28.128.101
```

- Now you can check if Ingress controllers are working.

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: localhost
    http:
      paths:
      - path: /
        backend:
          serviceName: my-nginx
          servicePort: 80
```

- Apply this config and check.

```console
[root@localhost ~]# curl http://localhost/
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

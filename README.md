# flux-grpcdemo

A weave flux deployment of a demo grpc server/client with prometheus-operator and istio. [Inspiration](https://github.com/stefanprodan/gitops-istio)

Components:

* **Istio** service mesh
    * manages the traffic flows between microservices, enforcing access policies and aggregating telemetry data
* **Prometheus** monitoring system  
    * time series database that collects and stores the service mesh metrics
* **Flux** GitOps operator
    * syncs YAMLs and Helm charts between git and clusters
    * scans container registries and deploys new images
* **Helm Operator** CRD controller
    * automates Helm chart releases
* **Flagger** progressive delivery operator
    * automates the promotion of canary deployments using Istio routing for traffic shifting and Prometheus metrics for canary analysis

### Prerequisites

You'll need a Kubernetes cluster **v1.11** or newer with `LoadBalancer` support, 
`MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers enabled. 
For testing purposes you can use Minikube with two CPUs and 4GB of memory. 

Install Flux CLI, Helm and Tiller:

```bash
brew install fluxctl kubernetes-helm

kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
--clusterrole=cluster-admin \
--serviceaccount=kube-system:tiller

helm init --service-account tiller --wait
```

Fork this repository and clone it:

```bash
git clone https://github.com/<YOUR-USERNAME>/gitops-istio
cd gitops-istio
```

### Cluster bootstrap

Install Weave Flux and its Helm Operator by specifying your fork URL:

```bash
./scripts/flux-init.sh git@github.com:<YOUR-USERNAME>/flux-grpcdemo
```

At startup, Flux generates a SSH key and logs the public key. The above command will print the public key. 

In order to sync your cluster state with git you need to copy the public key and create a deploy key with write 
access on your GitHub repository. On GitHub go to _Settings > Deploy keys_ click on _Add deploy key_, 
check _Allow write access_, paste the Flux public key and click _Add key_.

When Flux has write access to your repository it will do the following:

* creates the `istio-system` and `prod` namespaces
* creates the Istio CRDs
* installs Istio Helm Release
* installs Prometheus Operator Helm Release
* installs grpcdemo-client Helm Release
* installs grpcdemo-server Helm Release

### Cleanup

To delete everything that was installed (istio, promop, grpcdemo-client, grpcdemo-server, flux):

```
./scripts/cleanup.sh
```
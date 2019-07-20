# flux-grpcdemo

A weave flux deployment of a demo grpc server/client with prometheus-operator.

Components:

* **Prometheus** monitoring system  
    * time series database that collects and stores the service mesh metrics
* **Flux** GitOps operator
    * syncs YAMLs and Helm charts between git and clusters
    * scans container registries and deploys new images
* **Helm Operator** CRD controller
    * automates Helm chart releases
* **Kustomize**
	* used by flux to control environment-specific values for deployments (i.e. [staging](staging) vs [production](production))

### Inspirations

* [flux with kustomize](https://github.com/weaveworks/flux-kustomize-example)
* [flux with flagger canary deployment](https://github.com/stefanprodan/gitops-istio)


### Prerequisites

You'll need a Kubernetes cluster **v1.11** or newer. 
For testing purposes you can use Minikube. 

Install Flux CLI, Helm, hub on your local system:

```bash
brew install fluxctl kubernetes-helm hub
```

Install Tiller into your k8s cluster:

```bash
kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-role \
--clusterrole=cluster-admin \
--serviceaccount=kube-system:tiller

helm init --service-account tiller --wait
```

Fork this repository and clone it to your system:

```bash
git clone https://github.com/<YOUR-USERNAME>/flux-grpcdemo
cd flux-grpcdemo
```

### Cluster bootstrap

Install Weave Flux and its Helm Operator by specifying your username that owns your forked repo (i.e. jwenz723):

```bash
./scripts/flux-init.sh <YOUR-USERNAME>
```

At startup, Flux generates an SSH key and logs the public key. The above command will take that public key and add it into your github repository as a [deploy key](https://developer.github.com/v3/guides/managing-deploy-keys/) using the [hub](https://hub.github.com/) cli. If this fails, you can manually add the key. To manually retrieve the public key that should be added into github run:

```bash
fluxctl identity --k8s-fwd-ns flux
```

In order to sync your cluster state with git the public key needs to be stored as a deploy key with write 
access on your GitHub repository (you can also store it as a user ssh key). On GitHub go to _Settings > Deploy keys_ click on _Add deploy key_, 
check _Allow write access_, paste the Flux public key and click _Add key_.

When Flux has write access to your repository it will do the following:

* installs Prometheus Operator Helm Release
* installs grpcdemo-client Helm Release
* installs grpcdemo-server Helm Release

### Customizing the deploy per environment

Within this repository there is a [staging](staging) and [production](production) directory that contain configuration specific to each environment. These values are merged into the configuration contained in [base](base) by flux using [kustomize](https://kustomize.io/). This is accomplished by doing the following:

1. Create a [base](base) directory containing the base set of common configuration and a [kustomization.yaml](base/kustomization.yaml) file that tells kustomize what should be included in the base configuration.
2. Create 1 directory for each kustomized environment (i.e. staging and production) with a kustomization.yaml file within each environment directory to specify environment specifics
3. Add any environment-specific overrides into each environment directory (see [replicas-patch.yaml](production/replicas-patch.yaml) for an example) and setup each environmeont-specific kustmization.yaml file to make use of the overrides (see [kustomization.yaml](production/kustomization.yaml))
4. Create a [.flux.yaml](.flux.yaml) file that will run kustomize as a generator, according to [documentation](https://github.com/fluxcd/flux/blob/master/site/fluxyaml-config-files.md)
5. Install the flux helm chart with `git.path=<environment folder>` set to point at either `staging` or `production`. This is done within [flux-init.sh](scripts/flux-init.sh). By default it will point to the `staging` directory, but you can override this to point to the `production` directory by specifying a 2nd argument, for example:

	```bash
	./scripts/flux-init.sh <YOUR-USERNAME> production
	```

#### Environment Differences

* [staging](staging):
	* Doesn't specify any environment-specific overrides. Will use all configuration as specified in the base directory
* [production](production):
	* Sets the [replica count](production/replicas-patch.yaml) of HelmRelease grpcdemo-server to 2
	* Sets the [replica count](production/replicas-patch.yaml) of HelmRelease promop to 3

##### Demoing the Differences:

1. Install using the default staging directory:
	
	```bash
	./scripts/flux-init.sh <YOUR-USERNAME>
	```

2. After the installation has completed you can run the following commands to see the replica counts:
	
	* promop (should be 1 pod):

		```bash
		$ kubectl get pods -n promop -l app=prometheus
		NAME                                                 READY   STATUS    RESTARTS   AGE
		prometheus-promop-prometheus-operator-prometheus-0   3/3     Running   1          1m
		```

	* grpcdemo-server (should be 1 pod):

		```bash
		$ kubectl get pods -n grpcdemo -l app.kubernetes.io/name=grpcdemo-server
		NAME                               READY   STATUS    RESTARTS   AGE
		grpcdemo-server-6496988cb6-c7dgv   1/1     Running   1          1m
		```

3. Now run the install again specifying the production directory as a 2nd argument:

	```bash
	./scripts/flux-init.sh <YOUR-USERNAME> production
	```

4. After the installation has completed you can run the following commands to see the replica counts:
	
	* promop (should be 3 pods):

		```bash
		$ kubectl get pods -n promop -l app=prometheus
		NAME                                                 READY   STATUS    RESTARTS   AGE
		prometheus-promop-prometheus-operator-prometheus-0   3/3     Running   1          5m
		prometheus-promop-prometheus-operator-prometheus-1   3/3     Running   1          5m
		prometheus-promop-prometheus-operator-prometheus-2   3/3     Running   1          5m
		```

	* grpcdemo-server (should be 2 pods):

		```bash
		$ kubectl get pods -n grpcdemo -l app.kubernetes.io/name=grpcdemo-server
		NAME                               READY   STATUS    RESTARTS   AGE
		grpcdemo-server-6496988cb6-c7dgv   1/1     Running   1          5m
		grpcdemo-server-6496988cb6-sq99j   1/1     Running   0          5m
		```

5. Now revert back to staging by running the default install again:

	```bash
	./scripts/flux-init.sh <YOUR-USERNAME>
	```

### Cleanup

To delete everything that was installed (promop, grpcdemo-client, grpcdemo-server, flux):

```
./scripts/cleanup.sh
```

> NOTE: This command will not delete the github deploy key created by flux-init.sh.
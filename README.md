# MGH-GITOPS

```
-----------------------------------------------------------------------
brew install fluxcd/tap/flux
flux install
brew install argocd

### Option 3 - Install Flamingo from Scratch
Flux   Argo CD. Image
v2.0.1  v2.8   v2.8.0-rc6-fl.15-main-da46678f

kubectl create ns argocd
wget https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.0/manifests/install.yaml
kubectl apply -n argocd -f install.yaml

wget https://raw.githubusercontent.com/flux-subsystem-argo/flamingo/release-v2.8/release/kustomization.yaml
kubectl -n argocd apply -f kustomization.yaml
flux install


flamingo show-init-password
-----------------------------------------------------------------------
### Login to Argo CD UI
The default user name is `admin`.
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

kubectl get -n argocd pods
kubectl get pods -n flux-system
kubectl get -n argocd services
kubectl -n argocd port-forward svc/argocd-server 8080:443

-------
cat <<EOF | kubectl apply -f -
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: fsa-demo
  namespace: flux-system
  annotations:
    metadata.weave.works/flamingo-default-app: "https://localhost:8080/applications/argocd/default-app?view=tree"
    metadata.weave.works/flamingo-fsa-installation: "https://localhost:8080/applications/argocd/fsa-installation?view=tree"
    link.argocd.argoproj.io/external-link: "http://localhost:9001/oci/details?clusterName=Default&name=fsa-demo&namespace=flux-system"
spec:
  interval: 30s
  url: oci://ghcr.io/flux-subsystem-argo/flamingo/manifests
  ref:
    tag: v2.8
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: fsa-demo
  namespace: flux-system
  annotations:
    metadata.weave.works/flamingo-fsa-demo: "https://localhost:8080/applications/argocd/fsa-demo?view=tree"
    link.argocd.argoproj.io/external-link: "http://localhost:9001/kustomize/details?clusterName=Default&name=fsa-demo&namespace=flux-system"
spec:
  prune: true
  interval: 2m
  path: "./demo"
  sourceRef:
    kind: OCIRepository
    name: fsa-demo
  timeout: 3m
EOF
-------

connect github repo
argocd login localhost:8080
admin pass

argocd app list --server localhost:8080
argocd repo add git@github.com:jozemario/gitops.git --server localhost:8080 --ssh-private-key-path ~/.ssh/id_ed25519
argocd repo add https://github.com/jozemario/gitops.git --server localhost:8080 --username user --password pass

argocd repo add https://github.com/jozemario/gitops.git --server localhost:8080 --username admin --password q1HpKBvSBPFyzKo8

If the HEAD branch of the remote repository is one of the branches configured in your fetch refspecs, then this should work:

git remote set-head origin -a
This will query the remote for its HEAD and set origin/HEAD to point to the corresponding remote-tracking branch in your repository.

If the remote HEAD points to a branch thst is not covered by your fetch refspec, then you would have to add a fetch refspec for that branch, fetch it, and then run the above command.

https://flux-iac.github.io/tofu-controller/
https://flux-iac.github.io/tofu-controller/branch-planner/

--------
export TF_CON_VER=v0.16.0-rc.4
kubectl create -f tofu-controller/tf-controller.crds.yaml
kubectl create -f tofu-controller/tf-controller.rbac.yaml
kubectl create -f tofu-controller/tf-controller.deployment.yaml

kubectl delete -f tofu-controller/tf-controller.crds.yaml
kubectl delete -f tofu-controller/tf-controller.rbac.yaml
kubectl delete -f tofu-controller/tf-controller.deployment.yaml


kubectl create -f tofu-controller/tofu-controller.crds.yaml
kubectl create -f tofu-controller/tofu-controller.rbac.yaml
kubectl create -f tofu-controller/tofu-controller.deployment.yaml


kubectl delete -f tofu-controller/tofu-controller.crds.yaml
kubectl delete -f tofu-controller/tofu-controller.rbac.yaml
kubectl delete -f tofu-controller/tofu-controller.deployment.yaml
--------

kubectl get helmcharts --all-namespaces


helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-provider --set nfs.server=34.216.204.56 --set nfs.path=/var/uolshare/ nfs-subdir-external-provisioner/nfs-subdir-external-provisioner
```

### Quick start

```
Here's a simple example of how to GitOps your Terraform resources with TF-controller and Flux.

Define source
First, we need to define a Source controller's source (GitRepository, Bucket, OCIRepository), for example:


apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
name: helloworld
namespace: flux-system
spec:
interval: 30s
url: https://github.com/tf-controller/helloworld
ref:
branch: main
The GitOps Automation mode
The GitOps automation mode could be enabled by setting .spec.approvePlan=auto. In this mode, Terraform resources will be planned, and automatically applied for you.


apiVersion: infra.contrib.fluxcd.io/v1alpha2
kind: Terraform
metadata:
name: helloworld
namespace: flux-system
spec:
interval: 1m
approvePlan: auto
path: ./
sourceRef:
kind: GitRepository
name: helloworld
namespace: flux-system
For a full list of features and how to use them, please follow the Use TF-controller guide.
```

---

```
#branch planner

Create a secret that contains a GitHub API token. If you do not use the gh CLI, copy and paste the token from GitHub's website.

export GITHUB_TOKEN=$(gh auth token)

kubectl create secret generic branch-planner-token \
    --namespace=flux-system \
    --from-literal="token=${GITHUB_TOKEN}"

Create a Terraform object with a Source pointing to a repository. Your repository must contain a Terraform file—for example, main.tf. Check out this demo for an example.

export GITHUB_USER=<your user>
export GITHUB_REPO=<your repo>

cat <<EOF | kubectl apply -f -
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: branch-planner-demo
  namespace: flux-system
spec:
  interval: 30s
  url: https://github.com/${GITHUB_USER}/${GITHUB_REPO}
  ref:
    branch: main
---
apiVersion: infra.contrib.fluxcd.io/v1alpha2
kind: Terraform
metadata:
  name: branch-planner-demo
  namespace: flux-system
spec:
  approvePlan: auto
  path: ./
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: branch-planner-demo
    namespace: flux-system
EOF


kubectl apply -f infra/branch-planner.yaml


Now you can create a pull request on your GitHub repo. The Branch Planner will create a new Terraform object with the plan-only mode enabled and will generate a new plan for you. It will post the plan as a new comment in the pull request.
```

```
Configure Branch Planner
Branch Planner uses a ConfigMap as configuration. The ConfigMap is optional but useful for fine-tuning Branch Planner.

Configuration
By default, Branch Planner will look for the branch-planner ConfigMap in the same namespace as where the TF-Controller is installed. That ConfigMap allows users to specify which Terraform resources in a cluster the Brach Planner should monitor.

The ConfigMap has two fields:

secretName, which contains the API token to access GitHub.
resources, which defines a list of resources to watch.


cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: flux-system
  name: branch-planner
data:
  secretName: branch-planner-token
  resources: |-
    - namespace: dev
    - namespace: terraform
    - namespace: flux-system
EOF


Resources
If the resources list is empty, nothing will be watched. The resource definition can be exact or namespace-wide.

With the following configuration file, the Branch Planner will watch all Terraform objects in the terraform namespace, and the exact-terraform-object Terraform object in default namespace.


data:
  resources:
    - namespace: default
      name: exact-terraform-object
    - namespace: terraform
```

### START FROM SCRATCH

```
kubectl get nodes
chmod +x deploy-gitops.sh
./deploy-gitops.sh

The script will:
Install ArgoCD
Install Flamingo (Flux-ArgoCD integration)
Install FluxCD
Install Tofu Controller
Configure basic settings
Display the ArgoCD admin password
Provide instructions for accessing the ArgoCD UI

🔑 ArgoCD Admin Password:
YM8k6f9NBSq-ASEs

k3s
HyeYsI1FiWzCKoPk

🌐 Setting up port forwarding for ArgoCD UI...
Run the following command in a new terminal to access ArgoCD UI:
kubectl -n argocd port-forward svc/argocd-server 8080:443
✅ GitOps infrastructure deployment completed!
Access ArgoCD UI at: https://localhost:8080
Username: admin
```

### hello world example

it's time to create an App to manage our Terraform resource with Flux Subsystem for Argo. Please use the following configuration for the new App (helloworld)

Application Name: helloworld
Project: default
Sync Policy: Manual
Sync Options:
☑️ Auto-Create Namespace
☑️ Apply Out Of Sync Only
☑️ Use Flux Subsystem
☑️ Auto-Create Flux Resources
Repository URL: https://github.com/YOUR-GITHUB-ACCOUNT/tf-controller-helloworld
Revision: main
Path: ./infra
Cluster URL: https://kubernetes.default.svc
Namespace: dev
After create the App, press Sync button once and wait. You could also press Refresh to see if the graph already there. If everything is correct, you would get something like the following screenshot, with a nice Terraform icon!!

terraform-helloworld graph

What did this main.tf do? This Terraform file did not provision anything, expect an output, which you might see that it was written into a Secret named helloworld-outputs, also shown in the graph.

What's inside that output secrets, here's the command to help you find out.

kubectl -n dev get secret helloworld-outputs -o jsonpath="{.data.hello_world}" | base64 -d; echo

kubectl -n production get secret production-outputs -o jsonpath="{.data.environment}" | base64 -d; echo

kubectl get all -n dev
kubectl get pvc -n dev
kubectl get secrets -n dev

Setup local storage

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl apply -k bases/storage/

<!-- kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/refs/heads/master/examples/pvc-with-local-volume/pvc.yaml -->

kubectl patch ns <Namespace_to_delete> -p '{"metadata":{"finalizers":null}}'

kubectl patch ns dev -p '{"metadata":{"finalizers":null}}'
kubectl patch ns argocd -p '{"metadata":{"finalizers":null}}'

69

I loved this answer extracted from here It is just 2 commands.

In one terminal:

kubectl proxy
In another terminal:

kubectl get ns delete-me -o json | \
 jq '.spec.finalizers=[]' | \
 curl -X PUT http://localhost:8001/api/v1/namespaces/delete-me/finalize -H "Content-Type: application/json" --data @-

kubectl get ns podinfo-kustomize -o json | \
 jq '.spec.finalizers=[]' | \
 curl -X PUT http://localhost:8001/api/v1/namespaces/podinfo-kustomize/finalize -H "Content-Type: application/json" --data @-

export GITHUB_TOKEN=ghp_5555555555555555555555555555555555555555
kubectl create secret generic branch-planner-token \
 --namespace=flux-system \
 --from-literal="token=${GITHUB_TOKEN}"

helm repo add tf-controller https://flux-iac.github.io/tofu-controller

helm repo update

---

run setup script

add github token
add secret to k8s
create branch planner configmap

if you need to recreate the tofu controller, you need to delete the tofu-controller and delete tf roles and rolebinding and recreate the tofu controller.

kubectl -n flux-system get secret helloworld-outputs -o jsonpath="{.data.hello_world}" | base64 -d; echo

kubectl -n argocd rollout restart deployment/argocd-server

---

kubectl get ns delete-me -o json | \
 jq '.spec.finalizers=[]' | \
 curl -X PUT http://localhost:8001/api/v1/namespaces/delete-me/finalize -H "Content-Type: application/json" --data @-

kubectl delete all -n <namespace> --all
$ kubectl -n $NS patch $resource_name -p '{"metadata":{"finalizers":null}}' --type=merge

$ kubectl -n argocd patch argocd-redis-network-policy -p '{"metadata":{"finalizers":null}}' --type=merge

---

---

## NFS server

---

## sudo apt install nfs-kernel-server

Configure NFS Server to share directories on your Network.
This example is based on the environment like follows.
+----------------------+ | +----------------------+
| [ NFS Server ] |10.0.0.30 | 10.0.0.51| [ NFS Client ] |
| dlp.srv.world +----------+----------+ node01.srv.world |
| | | |
+----------------------+ +----------------------+

[1] Configure NFS Server.

root@dlp:~# apt -y install nfs-kernel-server
root@dlp:~# vi /etc/idmapd.conf

# line 5 : uncomment and change to your domain name

Domain = srv.world
root@dlp:~# vi /etc/exports

# add settings for NFS exports

# for example, set [/home/nfsshare] as NFS share

/home/nfsshare 10.0.0.0/24(rw,no_root_squash)
root@dlp:~# mkdir /home/nfsshare
root@dlp:~# systemctl restart nfs-server

## NFS client K3s

This example is based on the environment like follows.
+----------------------+ | +----------------------+
| [ NFS Server ] |10.0.0.30 | 10.0.0.51| [ NFS Client ] |
| dlp.srv.world +----------+----------+ node01.srv.world |
| | | |
+----------------------+ +----------------------+

[1] Configure NFS Client.
root@node01:~# apt -y install nfs-common
root@node01:~# vi /etc/idmapd.conf

# line 5 : uncomment and change to your domain name

Domain = srv.world
root@node01:~# mount -t nfs dlp.srv.world:/home/nfsshare /mnt
root@node01:~# df -hT
Filesystem Type Size Used Avail Use% Mounted on
tmpfs tmpfs 393M 1.1M 392M 1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv ext4 27G 5.6G 20G 23% /
tmpfs tmpfs 2.0G 0 2.0G 0% /dev/shm
tmpfs tmpfs 5.0M 0 5.0M 0% /run/lock
/dev/vda2 ext4 2.0G 125M 1.7G 7% /boot
tmpfs tmpfs 393M 4.0K 393M 1% /run/user/0
dlp.srv.world:/home/nfsshare nfs4 27G 5.6G 20G 23% /mnt

# NFS share is mounted

# if mount with NFSv3, add [-o vers=3] option

## root@node01:~# mount -t nfs -o vers=3 dlp.srv.world:/home/nfsshare /mnt

## K3s with NFS

First make sure to install the required package which is nfs-kernel-server since I am on piOS, installing it can be as easy as running the following command

sudo apt install nfs-kernel-server
Once you got it installed and ready on all your nods, you need to create a new manifests for K3s to automatically pick it up.

## You can create a file called nfs-controller.yml inside /var/lib/rancher/k3s/server/manifests/ and then add the following code to it:

apiVersion: v1
kind: Namespace
metadata:
name: default

---

apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
name: nfs
namespace: default
spec:
chart: nfs-subdir-external-provisioner
repo: https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
targetNamespace: default
set:
storageClass.name: nfs
valuesContent: |-
nfs:
server: 192.168.68.118
path: /i-data/f01e5fea/nfs/k3s
mountOptions: - nfsvers=3

---

vault helm chart

helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/vault

kubectl -n qa create secret generic vault-storage-config \
 --from-file=tf-qa/mghcloud/vault/config.hcl

helm install vault hashicorp/vault --namespace qa \
 --set='server.volumes[0].name=userconfig-vault-storage-config' \
 --set='server.volumes[0].secret.defaultMode=420' \
 --set='server.volumes[0].secret.secretName=vault-storage-config' \
 --set='server.volumeMounts[0].mountPath=/vault/userconfig/vault-storage-config' \
 --set='server.volumeMounts[0].name=userconfig-vault-storage-config' \
 --set='server.hostNetwork=true' \
 --set='server.service.type=NodePort' \
 --set='server.service.nodePort=30301' \
 --set='ui.enabled=true' \
 --set='ui.service.type=NodePort' \
 --set='ui.service.nodePort=30300' \
 --set='server.extraArgs=-config=/vault/userconfig/vault-storage-config/config.hcl'
% --set='server.standalone.config=`{ listener "tcp" { address = "0.0.0.0:8200" }}`'
--set='server.extraEnvironmentVars.VAULT_ADDR=http://192.168.10.206:30301' \

% --set='server.volumeMounts[0].readOnly=true' \
% --set='server.service.dataStorage.name=vault-pvc' \
% --set='server.service.dataStorage.storageClass=nfs' \
% --set='server.service.dataStorage.size=2Gi' \

---

Initialize Vault
kubectl -n qa get pods -l app.kubernetes.io/name=vault
Init vault ui
kubectl -n qa port-forward vault-0 8200:8200

kubectl -n qa exec -ti vault-0 -- vault operator init

kubectl -n qa exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json

vault operator init -address=http://localhost:8200 -key-shares=1 -key-threshold=1 -format=json > /vault/file/keys

vault operator init -address=http://127.0.0.1:8200 -key-shares=1 -key-threshold=1 -format=json > /vault/file/keys

kubectl -n qa exec vault-0 -- vault operator init -address=http://localhost:8200 -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json

kubectl -n qa exec vault-77845fc7c5-nv9jt -- vault operator init -address=http://localhost:8200 -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json

helm -n qa uninstall vault

export VAULT_ADDR=http://localhost:8200
export VAULT_CLIENT_TIMEOUT=500
export MY_VAULT_TOKEN=my-secure-token
./usr/local/bin/vault-init.sh

/app # apk update
fetch http://dl-cdn.alpinelinux.org/alpine/v3.7/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.7/community/x86_64/APKINDEX.tar.gz
v3.7.0-243-gf26e75a186 [http://dl-cdn.alpinelinux.org/alpine/v3.7/main]
v3.7.0-229-g087f28e29d [http://dl-cdn.alpinelinux.org/alpine/v3.7/community]
OK: 9051 distinct packages available

/app # apk add busybox-extras
(1/1) Installing busybox-extras (1.27.2-r11)
Executing busybox-extras-1.27.2-r11.post-install
Executing busybox-1.27.2-r7.trigger
OK: 77 MiB in 64 packages

/app # busybox-extras telnet localhost 6900

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
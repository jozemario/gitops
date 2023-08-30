# MGH-GITOPS

```
-----------------------------------------------------------------------
brew install fluxcd/tap/flux  
flux install
brew install argocd

### Option 3 - Install Flamingo from Scratch
Flux   Argo CD. Image
v2.0.1  v2.8   v2.8.0-rc6-fl.15-main-da46678f

export VERSION=v2.8.0-rc6-fl.15-main-da46678f
kubectl create ns argocd  
kubectl -n argocd apply -k https://github.com/flux-subsystem-argo/flamingo/release?ref=v2.8.0-rc6-fl.15-main-da46678f
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
    tag: v2.7
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
argocd login localhost:8080`
admin pass

argocd app list --server localhost:8080
argocd repo add git@github.com:jozemario/gitops.git --server localhost:8080 --ssh-private-key-path ~/.ssh/id_ed25519
argocd repo add https://github.com/jozemario/gitops.git --server localhost:8080 --username user --password pass


https://weaveworks.github.io/tf-controller/use_tf_controller/

kubectl get helmcharts --all-namespaces


helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-provider --set nfs.server=34.216.204.56 --set nfs.path=/var/uolshare/ nfs-subdir-external-provisioner/nfs-subdir-external-provisioner
```
### GitOps automation mode
```
The GitOps automation mode is the GitOps automation mode to be used to run the Terraform module. It determines how Terraform runs and manages your infrastructure. It is optional. If not specified, the "plan-and-manually-apply" mode will be used by default. In the "plan-and-manually-apply" mode, TF-controller will run a Terraform plan and output the proposed changes to a Git repository. A human must then review and manually apply the changes. This is the default GitOps automation mode if none is specified.

In the "auto-apply" mode, TF-controller will automatically apply the changes after a Terraform plan is run. This can be useful for environments where changes can be made automatically, but it is important to ensure that the proper controls, like policies, are in place to prevent unintended changes from being applied.

To specify the GitOps automation mode in a Terraform object, you can set the spec.approvePlan field to the desired value. For example, to use the "auto-apply" mode, y ou would set it to spec.approvePlan: auto.

It is important to carefully consider which GitOps automation mode is appropriate for your use case to ensure that your infrastructure is properly managed and controlled.

The following is an example of a Terraform object; we use the "auto-apply" mode:


apiVersion: infra.contrib.fluxcd.io/v1alpha2
kind: Terraform
metadata:
name: helloworld
spec:
path: ./helloworld
interval: 10m
approvePlan: auto
sourceRef:
kind: GitRepository
name: helloworld

This code is defining a Terraform object in Kubernetes. The apiVersion field specifies the version of the Kubernetes API being used, and the kind field specifies that it is a Terraform object. The metadata block contains information about the object, including its name.

The spec field contains the specification for the Terraform object. The path field specifies the path to the Terraform configuration files, in this case a directory named "helloworld". The interval field specifies the frequency at which TF-controller should run the Terraform configuration, in this case every 10 minutes. The approvePlan field specifies whether or not to automatically approve the changes proposed by a Terraform plan. In this case, it is set to auto, meaning that changes will be automatically approved.

The sourceRef field specifies the Flux source object to be used. In this case, it is a GitRepository object with the name "helloworld". This indicates that the Terraform configuration is stored in a Git repository object with the name helloworld.
```

#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 Starting GitOps Infrastructure Deployment"

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        exit 1
    fi
}

# Function to check if deployment is ready
check_deployment_ready() {
    namespace=$1
    deployment=$2
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n $namespace
}

# Check required tools
echo "📝 Checking required tools..."
check_command kubectl
check_command flux
check_command argocd

# Install ArgoCD
echo "📦 Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.0/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
sleep 30
check_deployment_ready argocd argocd-server

# Install Flamingo
echo "🦩 Installing Flamingo..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/flux-subsystem-argo/flamingo/release-v2.8/release/kustomization.yaml

# Install FluxCD
echo "🔄 Installing FluxCD..."
flux install

# Wait for Flux to be ready
echo "⏳ Waiting for Flux system to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/source-controller -n flux-system
kubectl wait --for=condition=available --timeout=300s deployment/kustomize-controller -n flux-system

kubectl create namespace staging
kubectl create namespace production
kubectl create namespace qa

argocd app list --server localhost:8080
# argocd repo add git@github.com:jozemario/gitops.git --server localhost:8080 --ssh-private-key-path ~/.ssh/id_ed25519


export TF_CON_VER=v0.16.0-rc.4
kubectl apply -f tofu-controller/tofu-controller.crds.yaml
kubectl apply -f tofu-controller/tofu-controller.rbac.yaml
kubectl apply -f tofu-controller/tofu-controller.deployment.yaml


# install ingress-nginx
# kubectl apply -k bases/ingress-nginx/

#install cert-manager
kubectl apply -k bases/cert-manager/
# kubectl apply -k bases/storage/
# For standalone Kustomize
# kustomize build ./my-kustomization/

# For Kubectl integrated Kustomize
# kubectl kustomize ./infra/


# The same Kustomization can be applied to a cluster like this:

# # For standalone Kustomize pipe into Kubectl
# kustomize build ./my-kustomization/ | kubectl apply -f -

# # For Kubectl integrated Kustomize
# kubectl apply -k ./infra/


# kubectl apply -k infra/.





# kubectl apply -f https://raw.githubusercontent.com/weaveworks/tf-controller/fa4b3b85d316340d897fda4fed757265ba2cd30e/docs/branch_planner/release.yaml
# kubectl delete -f https://raw.githubusercontent.com/weaveworks/tf-controller/fa4b3b85d316340d897fda4fed757265ba2cd30e/docs/branch_planner/release.yaml

# Install Tofu Controller
echo "🔧 Installing Tofu Controller..."
# export TF_CON_VER=v0.16.0-rc.4
# kubectl apply -f tofu-controller/tofu-controller.crds.yaml
# kubectl apply -f tofu-controller/tofu-controller.rbac.yaml
# kubectl apply -f tofu-controller/tofu-controller.deployment.yaml
# Add tofu-controller helm repository
# helm repo add tofu-controller https://flux-iac.github.io/tofu-controller/
# helm repo update
# # Install tofu-controller
# helm upgrade -i tofu-controller tofu-controller/tofu-controller \
#     --namespace flux-system

# Get ArgoCD admin password
echo -e "${GREEN}🔑 ArgoCD Admin Password:${NC}"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

# Setup port forwarding for ArgoCD UI
echo "🌐 Setting up port forwarding for ArgoCD UI..."
echo "Run the following command in a new terminal to access ArgoCD UI:"
echo "kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo -e "${GREEN}✅ GitOps infrastructure deployment completed!${NC}"
echo "Access ArgoCD UI at: https://localhost:8080"
echo "Username: admin"


# flux get kustomization 
# flux get sources git
# flux get helmcharts
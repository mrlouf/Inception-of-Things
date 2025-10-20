#!/bin/bash

# Install Docker first if not present:
if ! systemctl is-active --quiet docker; then
    echo "Installing Docker..."
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    
    # Actually install Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
else
    echo "Docker already installed and running"
fi

# Install k3d
echo "Starting k3d..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash


# Install kubectl
if command -v kubectl &> /dev/null; then
    echo "kubectl is already installed"
else
    echo "kubectl not found, installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi

# Verify kubectl installation
kubectl version --client
k3d cluster create mycluster --agents 2 --wait
export KUBECONFIG=$(k3d kubeconfig write mycluster)

# Setup ArgoCD namespace and install CLI
echo "Installing ArgoCD CLI..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo kubectl wait -n argocd --for=condition=Ready pods --all --timeout=300s

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/download/${VERSION}/argocd-linux-amd64"
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Deploy the application using ArgoCD
echo "Deploying application using ArgoCD..."
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n dev -f https://raw.githubusercontent.com/mrlouf/nponchon-IoT/main/deployment.yaml
kubectl apply -f argocd-myapp.yaml

echo "You can access the application at http://localhost:8888"
kubectl port-forward service/argocd-server -n argocd 8080:443
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
    rm kubectl
fi

k3d cluster create mycluster --agents 2 --wait --port 80:80@loadbalancer --port 443:443@loadbalancer
export KUBECONFIG=$(k3d kubeconfig write mycluster)

# Setup ArgoCD namespace and install CLI
echo -e "\e[34mInstalling ArgoCD...\e[0m"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "\e[33mWaiting for ArgoCD pods to be ready...\e[0m"
kubectl wait -n argocd --for=condition=Ready pods --all --timeout=300s

# Patch ArgoCD server to run in insecure mode
kubectl patch deployment argocd-server -n argocd --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'
kubectl rollout status deployment/argocd-server -n argocd

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Install ArgoCD CLI
echo -e "\e[34mInstalling ArgoCD CLI...\e[0m"
VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/download/${VERSION}/argocd-linux-amd64"
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Deploy the application using ArgoCD
echo -e "\e[34mDeploying application using ArgoCD...\e[0m"
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n dev -f https://raw.githubusercontent.com/mrlouf/nponchon-IoT/main/deployment.yaml
kubectl apply -f argocd-myapp.yaml

# Apply Ingress configurations
echo -e "\e[34mApplying Ingress configurations...\e[0m"
kubectl apply -f ingress.yaml

echo -e "\e[32m============================================\e[0m"
echo -e "\e[32mApplication: \e[1mhttp://myapp.localhost\e[0m"
echo -e "\e[32mArgoCD UI:   \e[1mhttp://argocd.localhost\e[0m"
echo -e "\e[32m  Username: admin\e[0m"
echo -e "\e[32m  Password: $ARGOCD_PASSWORD\e[0m"
echo -e "\e[32m============================================\e[0m"
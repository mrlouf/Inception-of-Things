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

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Setup k3d                      #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
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

# create a k3d cluster and map ports
k3d cluster create mycluster --agents 2 --wait \
    --port 80:80@loadbalancer \
    --port 443:443@loadbalancer \
    --port 8080:8080@loadbalancer \
    --port 2222:2222@loadbalancer
# set the kubeconfig context
export KUBECONFIG=$(k3d kubeconfig write mycluster)

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Install ArgoCD                 #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
echo -e "\e[34mInstalling ArgoCD...\e[0m"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "\e[33mWaiting for ArgoCD pods to be ready...\e[0m"
kubectl wait -n argocd --for=condition=Ready pods --all --timeout=300s

# Patch ArgoCD server to run in insecure mode (required for HTTP Ingress)
echo -e "\e[34mConfiguring ArgoCD for HTTP Ingress...\e[0m"
kubectl patch deployment argocd-server -n argocd --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/command/-","value":"--insecure"}]'
kubectl rollout status deployment/argocd-server -n argocd

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Install ArgoCD CLI
echo -e "\e[34mInstalling ArgoCD CLI...\e[0m"
VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/download/${VERSION}/argocd-linux-amd64"
chmod +x argocd
sudo mv argocd /usr/local/bin/

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Install Helm                   #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
# Install Helm
echo -e "\e[34mInstalling Helm...\e[0m"
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Install GitLab                 #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
# Add GitLab Helm repository
echo -e "\e[34mInstalling GitLab...\e[0m"
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Create namespace for GitLab
kubectl create namespace gitlab
helm install my-gitlab gitlab/gitlab --namespace gitlab -f gitlab-values.yaml

# Wait for GitLab to be ready
echo -e "\e[33mWaiting for GitLab to be ready (this may take several minutes)...\e[0m"
kubectl wait -n gitlab --for=condition=Ready pods -l app=webservice --timeout=600s

GITLAB_ROOT_PASSWORD=$(kubectl get secret -n gitlab my-gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode)

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#         Configure SSH Keys for ArgoCD->GitLab    #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
echo -e "\e[34mGenerating SSH key for ArgoCD...\e[0m"
SSH_KEY_PATH="$HOME/.ssh/argocd-gitlab"

# Generate SSH key if it doesn't exist
if [ ! -f "$SSH_KEY_PATH" ]; then
    ssh-keygen -t ed25519 -C "argocd@cluster" -f "$SSH_KEY_PATH" -N ""
    echo -e "\e[32m✓ SSH key generated at $SSH_KEY_PATH\e[0m"
else
    echo -e "\e[33m⚠ SSH key already exists at $SSH_KEY_PATH\e[0m"
fi

# Create ArgoCD repository secret with SSH credentials
echo -e "\e[34mConfiguring ArgoCD repository credentials...\e[0m"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ssh://git@my-gitlab-gitlab-shell.gitlab.svc.cluster.local:22/root/nponchon-iot.git
  sshPrivateKey: |
$(cat "$SSH_KEY_PATH" | sed 's/^/    /')
  insecure: "true"
EOF

echo -e "\e[32m✓ ArgoCD repository credentials configured\e[0m"

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#              Deploy Application via ArgoCD       #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
echo -e "\e[34mDeploying application using ArgoCD...\e[0m"
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n dev -f https://raw.githubusercontent.com/mrlouf/nponchon-IoT/main/deployment.yaml

# Apply ArgoCD application manifest (will fail initially until GitLab repo is configured)
kubectl apply -f argocd-myapp.yaml

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                 Apply Ingress Rules              #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
echo -e "\e[34mApplying Ingress configurations...\e[0m"
kubectl apply -f ingress.yaml

#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
#                   Summary Output                 #
#~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=#
echo -e "\e[32m============================================\e[0m"
echo -e "\e[32m✓ Setup Complete!\e[0m"
echo -e "\e[32m============================================\e[0m"
echo -e "\e[32mApplication: \e[1mhttp://myapp.localhost\e[0m"
echo -e "\e[32mArgoCD UI:   \e[1mhttp://argocd.localhost\e[0m"
echo -e "\e[32mGitLab UI:   \e[1mhttp://gitlab.localhost\e[0m"
echo -e "\e[32m--------------------------------------------\e[0m"
echo -e "\e[32mArgoCD Initial Admin Credentials:\e[0m"
echo -e "\e[32m  Username: admin\e[0m"
echo -e "\e[32m  Password: $ARGOCD_PASSWORD\e[0m"
echo -e "\e[32m--------------------------------------------\e[0m"
echo -e "\e[32mGitLab Initial Root Credentials:\e[0m"
echo -e "\e[32m  Username: root\e[0m"
echo -e "\e[32m  Password: $GITLAB_ROOT_PASSWORD\e[0m"
echo -e "\e[32m--------------------------------------------\e[0m"
echo -e "\e[33m⚠ MANUAL STEPS REQUIRED:\e[0m"
echo -e "\e[33m1. Add SSH Deploy Key to GitLab:\e[0m"
echo -e "\e[33m   - Login to GitLab at http://gitlab.localhost\e[0m"
echo -e "\e[33m   - Create project: root/nponchon-iot\e[0m"
echo -e "\e[33m   - Go to Settings → Repository → Deploy Keys\e[0m"
echo -e "\e[33m   - Add this public key:\e[0m"
echo ""
cat "$SSH_KEY_PATH.pub"
echo ""
echo -e "\e[33m2. Push your application code to GitLab:\e[0m"
echo -e "\e[33m   git remote add gitlab git@gitlab.localhost:root/nponchon-iot.git\e[0m"
echo -e "\e[33m   git push gitlab main\e[0m"
echo -e "\e[33m3. Sync ArgoCD application from the UI\e[0m"
echo -e "\e[32m============================================\e[0m"
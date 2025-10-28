k3d cluster delete mycluster
rm -f ~/.kube/config

kubectl delete namespace argocd
sudo rm -f ~/.ssh/argocd-gitlab ~/.ssh/argocd-gitlab.pub

docker ps -a | grep k3d | awk '{print $1}' | xargs -r docker rm -f
docker system prune -af --volumes

docker images | grep k3d | awk '{print $3}' | xargs -r docker rmi -f
docker images | grep k3s | awk '{print $3}' | xargs -r docker rmi -f

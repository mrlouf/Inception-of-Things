k3d cluster delete mycluster --ignore-not-found
rm -f ~/.kube/config

kubectl delete namespace argocd --ignore-not-found
sudo rm -f /usr/local/bin/argocd

docker ps -a | grep k3d | awk '{print $1}' | xargs -r docker rm -f
docker system prune -a -f --volumes

docker images | grep k3d | awk '{print $3}' | xargs -r docker rmi -f
docker images | grep k3s | awk '{print $3}' | xargs -r docker rmi -f
k3d cluster delete mycluster
k3d cluster list
k3d cluster delete --all

docker ps -a | grep k3d | awk '{print $1}' | xargs -r docker rm -f
docker system prune -a -f --volumes

docker images | grep k3d | awk '{print $3}' | xargs -r docker rmi -f
docker images | grep k3s | awk '{print $3}' | xargs -r docker rmi -f
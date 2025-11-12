#  Inception-of-Things

## Overview
This project aims at giving a small introduction to Kubernetes (k8s) by implementing a serie of micro-infrastructures using k3s, a lightweight Kubernetes distribution and k3d, a tool to run k3s in Docker containers. Each micro-infrastructure will be deployed inside a k3s cluster and will showcase different aspects of Kubernetes, such as deploying applications, configuring networking with Ingress, and managing resources with Helm with the ultimate goal of setting up a complete CI/CD pipeline.

## What is Kubernetes?
In simple terms, Kubernetes is an open-source platform designed to automate the deployment, scaling, and operation of application containers.
If you are like me and analogies help you understand complex and abstract concepts, here's a good one: 
>> You can think of a container orchestrator (like Kubernetes ) as you would a conductor for an orchestra, says Dave Egts, chief technologist, North America Public Sector, Red Hat. “In the same way a conductor would say how many trumpets are needed, which ones play first trumpet, and how loud each should play," Egts explains, "a container orchestrator would say how many web server front end containers are needed, what they serve, and how many resources are to be dedicated to each one."<br>

(Quoted from this [article](https://www.redhat.com/en/topics/containers/what-is-kubernetes)).

## Prerequisites
P1 and P2 require Vagrant and VirtualBox to be installed on your machine:
1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) on your machine.
2. Install [Vagrant](https://www.vagrantup.com/downloads) on your machine.

P3 and the bonus part require Docker to be installed on your machine:
1. Install [Docker](https://docs.docker.com/get-docker/) on your machine.

## Project Structure
<img width="500" height="800" alt="image" src="https://github.com/user-attachments/assets/3f2d1aea-79bd-4fa9-b9ee-294bdb993f18" />



### P1:
- This part focuses on setting up a simple k3s cluster using Vagrant with one Server node and one Agent node.
- The subject requires to set a specific IP for each node and set them up in the right mode (Server/Agent).

### P2:
- This part reuses the Server node from P1 and requires to create a cluster with 3 Agent nodes.
- Consult the [Readme file](https://github.com/mrlouf/Inception-of-Things/tree/main/p2) made by mcatalan for more information about this part.

### P3:
- This part no longer uses Vagrant but instead uses k3d to create a k3s cluster inside Docker containers.
- The cluster will have one Server node and two Agent nodes, and the goal is to deploy a simple application (Wil's image) and ArgoCD to manage the application deployment.
- ArgoCD is a GitOps continuous delivery tool for Kubernetes that automates the deployment of the desired application states in the specified target environments. It continuously monitors a specific Git repository for changes (be it a specific commit or branch) and applies those changes to the Kubernetes cluster, ensuring that the cluster's state matches the desired state defined in the Git repository. In this part, we created a GitHub repository containing the manifest files for both the application, and configured ArgoCD to monitor that repository and automatically deploy the application whenever changes are pushed to the repository.
- The application and ArgoCD are exposed using an Ingress controller.

### Bonus:
- This part extends P3 by adding Helm to manage the local deployment of Gitlab inside the k3s cluster. Gitlab is a web-based DevOps tool that provides a Git repository manager, CI/CD pipeline features, and more.
- Helm is a package manager for Kubernetes that simplifies the deployment and management of applications by using pre-configured charts. You can think of Helm as the equivalent of apt for Kubernetes.
- Gitlab will be used to host the repository containing the application manifest and ArgoCD will be configured to monitor the Gitlab repository instead of GitHub.
- The Gitlab instance is exposed using an Ingress controller, just like ArgoCD and the application in P3, to make it accessible from outside the cluster.

#### About the bonus and resource limitations
Due to the limited resources of the computers at 42 (8GB RAM), running Gitlab inside the k3s cluster can be quite challenging, if not impossible, on a standard VM hosted on sgoinfre. Our solution to that was to host the VM on a SSD external drive, which significantly improved performance, but that was not enough. We had to tweak Gitlab's configuration to reduce its resource consumption by disabling unnecessary components and limiting the resources allocated to each component.
While P1, P2, and P3 could be run on a Debian VM, the bonus required a slicker image with less overhead, hence the use of a custom Alpine VM as a base, on which we had to set up a fileswap of 4 GB to compensate and avoid the dreaded OOM killer.

## Sources and References
- [What are clusters, nodes and pods?](https://www.cloudzero.com/blog/kubernetes-node-vs-pod/)
- [Simple explanation of Kubernetes from Reddit](https://www.reddit.com/r/kubernetes/comments/1e3v1e3/when_to_use_pods_vs_nodes/)
- [Understanding ArgoCD and GitOps](https://codefresh.io/learn/argo-cd/)
- [What is Helm, and why use it?](https://helm.sh/docs/intro/quickstart)
- [Gitlab Documentation](https://docs.gitlab.com/)

## Special Thanks
Special thanks to [Fabio](https://github.com/fabbbiodc) for the custom VM used for the bonus, without which setting up Gitlab would have been impossible on 42's limited computers.

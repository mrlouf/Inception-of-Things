#  Inception-of-Things

## Overview
This project aims at giving a small introduction to Kubernetes (k8s) by implementing a serie of micro-infrastructures using k3s, a lightweight Kubernetes distribution and k3d, a tool to run k3s in Docker containers. Each micro-infrastructure will be deployed inside a k3s cluster and will showcase different aspects of Kubernetes, such as deploying applications, configuring networking with Ingress, and managing resources with Helm with the ultimate goal of setting up a complete CI/CD pipeline.

## Prerequisites
P1 and P2 require Vagrant and VirtualBox to be installed on your machine:
1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) on your machine.
2. Install [Vagrant](https://www.vagrantup.com/downloads) on your machine.

P3 and the bonus part require Docker to be installed on your machine:
1. Install [Docker](https://docs.docker.com/get-docker/) on your machine.

## Project Structure
<img width="500" height="800" alt="image" src="https://github.com/user-attachments/assets/3f2d1aea-79bd-4fa9-b9ee-294bdb993f18" />



P1:
- This part focuses on setting up a simple k3s cluster using Vagrant with one Server node and one Agent node.
- The subject requires to set a specific IP for each node and set them up in the right mode (Server/Agent).

P2:
- This part reuses the Server node from P1 and requires to create a cluster with 3 Agent nodes.
- Consult the [Readme file](https://github.com/mrlouf/Inception-of-Things/tree/main/p2) made by mcatalan for more information about this part.

P3:
- This part no longer uses Vagrant but instead uses k3d to create a k3s cluster inside Docker containers.
- The cluster will have one Server node and two Agent nodes, and the goal is to deploy a simple application (Wil's image) and ArgoCD to manage the application deployment. ArgoCD will be configured to use a GitHub repository as the source for the application manifest and will monitor the main branch for commits to automatically deploy updates.
- The application and ArgoCD will be exposed using an Ingress controller.

Bonus:
- This part extends P3 by adding Helm to manage the local deployment of Gitlab inside the k3s cluster.
- Gitlab will be used to host the repository containing the application manifest and ArgoCD will be configured to monitor the Gitlab repository instead of GitHub.

## Sources and References
- [k3s Documentation](https://k3s.io/)
- [k3d Documentation](https://k3d.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/en/stable/)
- [Helm Documentation](https://helm.sh/docs/)
- [Gitlab Documentation](https://docs.gitlab.com/)

## Special Thanks
Special thanks to [Fabio](https://github.com/fabbbiodc) for the custom VM used for the bonus, without which setting up Gitlab would have been impossible on 42's limited computers.

# FastAPI Application on AWS-EKS

A cloud-native FastAPI microservice deployed on Amazon EKS using
Terraform for infrastructure provisioning and Helm for Kubernetes
add-ons.

This project demonstrates a production-style Kubernetes setup including
CI/CD, ingress routing, autoscaling, and full observability.

------------------------------------------------------------------------

## Overview

The platform includes:

-   Amazon EKS cluster provisioned with Terraform
-   Managed node groups with Cluster Autoscaler
-   NGINX Ingress Controller exposed via AWS NLB
-   Horizontal Pod Autoscaler (HPA)
-   GitHub Actions CI/CD pipeline
-   Prometheus & Grafana monitoring stack
-   Loki for log aggregation with AWS S3 as storage backend
-   IRSA for secure AWS access from pods

------------------------------------------------------------------------

## Architecture Components

### Infrastructure (Terraform)

-   VPC
-   EKS cluster
-   Managed node groups
-   IAM roles and IRSA configuration
-   S3 bucket for Loki log storage
-   Helm releases for:
    -   ingress-nginx
    -   kube-prometheus-stack
    -   Loki
    -   Cluster Autoscaler

### Application Layer

-   FastAPI application (stateless)
-   Docker containerized
-   Kubernetes Deployment & Service
-   Namespace isolation
-   Resource requests and limits configured

### Networking & Scaling

-   NGINX Ingress Controller (AWS Network Load Balancer)
-   Horizontal Pod Autoscaler (CPU-based scaling)
-   Cluster Autoscaler (node-level scaling)

### Observability

-   Prometheus scraping application metrics via ServiceMonitor
-   Grafana dashboards exposed via Ingress
-   Loki aggregating container logs
-   Logs stored in Amazon S3 for durability

### CI/CD

GitHub Actions workflows automate:

-   Docker image build
-   Image push to registry
-   Infrastructure deployment 
-   Application deployment 


------------------------------------------------------------------------

## Project Structure

app/ → FastAPI source code\
kubernetes/app/ → Kubernetes manifests (Deployment, Service, HPA,
Ingress, ServiceMonitor)\
terraform/ → Infrastructure modules and Helm releases\
.github/workflows/ → CI/CD pipelines\
Dockerfile → Container definition

------------------------------------------------------------------------

## Run Locally

python3 -m venv venv\
source venv/bin/activate\
pip install -r requirements.txt\
uvicorn app.main:app --reload

Application runs at:

http://localhost:8000

------------------------------------------------------------------------

## Provision Infrastructure

cd terraform\
terraform init\
terraform apply

Configure kubectl:

aws eks update-kubeconfig --region `<region>`{=html} --name
`<cluster-name>`{=html}

------------------------------------------------------------------------

## Deploy Application

kubectl apply -f kubernetes/app/\
kubectl get pods\
kubectl get svc\
kubectl get ingress

------------------------------------------------------------------------

## Key Design Decisions

-   Stateless application for horizontal scalability
-   IRSA used instead of static AWS credentials
-   Helm provider used to manage cluster add-ons declaratively
-   Separate infrastructure and application layers
-   Node and pod autoscaling enabled for elasticity

------------------------------------------------------------------------

## Cleanup

terraform destroy

------------------------------------------------------------------------

Author: Arjun M

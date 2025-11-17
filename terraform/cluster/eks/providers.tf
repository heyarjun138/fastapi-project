
# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Waiting the cluster to be ready

resource "null_resource" "wait_for_eks_api" {
  depends_on = [
    module.eks,
    module.eks.module.eks_managed_node_group
  ]

  provisioner "local-exec" {
    command = <<EOF
echo "Waiting for EKS API endpoint to respond..."
endpoint="${module.eks.cluster_endpoint}"

for i in $(seq 1 30); do
  if curl -s --connect-timeout 5 "$endpoint/version" >/dev/null 2>&1; then
    echo "EKS API is reachable!"
    exit 0
  fi
  echo "Still waiting... ($i/30)"
  sleep 10
done

echo "EKS API NOT reachable after 5 minutes"
exit 1
EOF
  }
}


# Data sources for EKS cluster (ensure readiness)

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks, null_resource.wait_for_eks_api]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks, null_resource.wait_for_eks_api]
}




# Configure K8 Provider

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token

}


# Configure the Helm Provider

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    #load_config_file = false
  }
}

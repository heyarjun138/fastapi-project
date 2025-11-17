# Terraform module to create Amazon Elastic Kubernetes

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.4.0"
  name               = var.cluster_name
  kubernetes_version = var.k8_version

  enable_irsa = true

  addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
  }
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = ["0.0.0.0/0"]   # your github ips & home IP

  # Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true


  vpc_id                   = data.terraform_remote_state.global.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.global.outputs.private_subnet_ids
  control_plane_subnet_ids = data.terraform_remote_state.global.outputs.private_subnet_ids
  access_entries = {
    my_admin_user = {
      principal_arn = "arn:aws:iam::677938781728:user/Arjun"

      kubernetes_groups = ["system:masters"]

      type = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  # EKS Managed Node Group
  eks_managed_node_groups = {

    # single workernode group with 1 desired EC2 instance
    workernode = {

      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.instance_type]

      min_size     = var.min_count
      max_size     = var.max_count
      desired_size = var.desired_count
    }
  }

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}





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
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      most_recent = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      before_compute = true
      most_recent    = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = ["0.0.0.0/0"] # NEED TO CHANGE THE VALUE OF PUBLIC IP IN HERE

  # Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = data.terraform_remote_state.global.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.global.outputs.private_subnet_ids
  control_plane_subnet_ids = data.terraform_remote_state.global.outputs.private_subnet_ids

  # EKS Managed Node Group
  eks_managed_node_groups = {

    # single workernode group with 1 desired EC2 instance
    workernode = {
      #depends_on = [module.eks.cluster_name]
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.instance_type] # later change to t3.medium

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

# Admin user
resource "aws_eks_access_entry" "local_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::677938781728:user/Arjun"
  type          = "STANDARD"
  depends_on    = [module.eks]
}

resource "aws_eks_access_policy_association" "local_admin_cluster_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.local_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Github Action Role
/*resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::677938781728:role/github-actions-iam-role"
  type          = "STANDARD"
  depends_on    = [module.eks]
}*/

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.github_actions.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}


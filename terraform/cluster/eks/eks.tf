##############################
# EKS CLUSTER MODULE (v21.4.0)
##############################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.4.0"

  name               = var.cluster_name
  kubernetes_version = var.k8_version

  enable_irsa = true

  ###########################################
  # EKS ADDONS (latest, stable & recommended)
  ###########################################
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

  ###########################################
  # CLUSTER ENDPOINT ACCESS
  ###########################################
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = ["0.0.0.0/0"]   # Replace with GitHub runners & your home IP

  #########################################################################
  # THIS GRANTS YOUR IDENTITY ADMIN ACCESS AUTOMATICALLY (GOOD FOR LOCAL)
  #########################################################################
  enable_cluster_creator_admin_permissions = true

  ###########################################
  # VPC & SUBNET INPUTS
  ###########################################
  vpc_id                   = data.terraform_remote_state.global.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.global.outputs.private_subnet_ids
  control_plane_subnet_ids = data.terraform_remote_state.global.outputs.private_subnet_ids

  ###########################################
  # ACCESS ENTRIES (Kubernetes RBAC Mappings)
  ###########################################
  access_entries = {
    # ------------------------------------
    # ADMIN ACCESS FOR YOUR IAM USER
    # ------------------------------------
    my_admin_user = {
      principal_arn     = "arn:aws:iam::677938781728:user/Arjun"
      kubernetes_groups = ["system:masters"]
      type              = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # ------------------------------------
    # NODE ACCESS (REQUIRED!)
    # Without system:bootstrappers, nodes fail to join
    # ------------------------------------
    node_access = {
      principal_arn = module.eks.eks_managed_node_groups["workernode"].iam_role_arn

      kubernetes_groups = [
        "system:bootstrappers",
        "system:nodes"
      ]

      type = "EC2_LINUX"
    }
  }

  ###########################################
  # EKS MANAGED NODE GROUP
  ###########################################
  eks_managed_node_groups = {
    workernode = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.instance_type]

      min_size     = var.min_count
      max_size     = var.max_count
      desired_size = var.desired_count
    }
  }

  ###########################################
  # TAGS
  ###########################################
  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

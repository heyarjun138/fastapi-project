#############################################
# FINAL EKS CLUSTER MODULE (v21.4.0)
#############################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.4.0"

  name               = var.cluster_name
  kubernetes_version = var.k8_version

  enable_irsa = true

  ###########################################
  # EKS ADDONS
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
  endpoint_public_access_cidrs = ["0.0.0.0/0"]   # allow laptop + GitHub runners

  ###########################################
  # NETWORKING
  ###########################################
  vpc_id                   = data.terraform_remote_state.global.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.global.outputs.private_subnet_ids
  control_plane_subnet_ids = data.terraform_remote_state.global.outputs.private_subnet_ids

  ###########################################
  # ACCESS ENTRIES (IAM → Kubernetes RBAC)
  ###########################################
  access_entries = {
    #########################################
    # 1. LOCAL USER (ARJUN) → ADMIN
    #########################################
    admin_user = {
      principal_arn     = "arn:aws:iam::677938781728:user/Arjun"
      kubernetes_groups = ["system:masters"]
      type              = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    #########################################
    # 2. GITHUB ACTIONS ROLE → ADMIN
    #########################################
    github_actions = {
      principal_arn     = "arn:aws:iam::677938781728:role/github-actions-iam-role"
      kubernetes_groups = ["system:masters"]
      type              = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }  # <-- THIS WAS MISSING (Closing access_entries block)

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

#############################################
# NODE ACCESS MUST BE OUTSIDE THE MODULE
#############################################
resource "aws_eks_access_entry" "node_access" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.eks.node_iam_role_arn
  type          = "EC2_LINUX"

  kubernetes_groups = [
    "system:bootstrappers",
    "system:nodes",
  ]

  depends_on = [
    module.eks
  ]
}


data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}


locals {
  oidc_url = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

# LOKI IRSA Role - 
# This IAM role is used by the Loki service account in the "monitoring" namespace
# to access its S3 bucket for storing logs and index data.

resource "aws_iam_role" "loki_irsa_role" {
  name = var.loki_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_url}:sub" = "system:serviceaccount:monitoring:loki-sa",
            "${local.oidc_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  depends_on = [module.eks]
}


resource "aws_iam_role_policy_attachment" "loki_s3_attach" {
  role       = aws_iam_role.loki_irsa_role.name
  policy_arn = aws_iam_policy.loki_s3_policy.arn
}


# Cluster Autoscaler IRSA Role
# This IAM role is used by the Cluster Autoscaler running in
# the "kube-system" namespace to dynamically adjust the size
# of EKS node groups based on resource utilization.

resource "aws_iam_role" "cluster_autoscaler" {
  name = "cluster_autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn #from EKS module output
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler", #from EKS module output
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"

          }
        }
      }
    ]
  })
  depends_on = [module.eks]
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_asg_attach" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
}

# Ingress-nginx IRSA Role
# This IAM role is assumed by the NGINX Ingress Controller's
# service account in the "ingress-nginx" namespace via IRSA

resource "aws_iam_role" "ingress_nginx_irsa_role" {
  name = "ingress_nginx"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:ingress-nginx:ingress-nginx",
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"

          }
        }
      }
    ]
  })
  depends_on = [module.eks]
}

resource "aws_iam_role_policy_attachment" "ingress_nginx_lb_attach" {
  role       = aws_iam_role.ingress_nginx_irsa_role.name
  policy_arn = aws_iam_policy.nginx_lb_policy.arn
}

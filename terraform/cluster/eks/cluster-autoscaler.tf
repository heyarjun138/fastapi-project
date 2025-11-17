
data "aws_region" "current" {} # provides details about a specific AWS Region

# Helm release to deploy Cluster Autoscaler Helm Chart
/*
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_chart_version
  namespace  = var.cluster_autoscaler_namespace
  timeout    = 600
  wait       = true

  values = [<<-EOF
    apiVersionOverrides:
      podDisruptionBudget: policy/v1
    autoDiscovery:
      clusterName: ${module.eks.cluster_name}
    awsRegion: ${data.aws_region.current.region}
    rbac:
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: ${aws_iam_role.cluster_autoscaler.arn}
        create: true
        name: cluster-autoscaler
  EOF
  ]
  depends_on = [null_resource.wait_for_eks_api, aws_iam_role.cluster_autoscaler]
}
*/
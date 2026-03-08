# Creating namespace

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Deploying Loki Helm Chart
/*
module "loki-stack" {
  source  = "terraform-iaac/loki-stack/kubernetes"
  version = "1.3.1"

  # Provider type
  provider_type    = "aws" # Use an emptyDir volume to store logs temporarily
  create_namespace = false

  #  Add this override
  loki_docker_image = "grafana/loki:2.9.3"

  promtail_docker_image = "grafana/promtail:2.9.3"

  #Storage details
  s3_name   = aws_s3_bucket.loki_s3.bucket
  s3_region = var.aws_region
  namespace = kubernetes_namespace.monitoring.metadata[0].name
  
  #for IRSA
  loki_service_account_annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.loki_irsa_role.arn
  }


  depends_on = [null_resource.wait_for_eks_api, aws_s3_bucket.loki_s3, aws_iam_role.loki_irsa_role, kubernetes_namespace.monitoring]
}
*/

resource "helm_release" "loki_stack" {

  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"

  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/loki-values/values.yaml", {
      loki_bucket  = aws_s3_bucket.loki_s3.bucket
      aws_region   = var.aws_region
      tenant_id    = "fastapi-production"
      loki_url     = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
      iam_role_arn = aws_iam_role.loki_irsa_role.arn
    })
  ]

  depends_on = [null_resource.wait_for_eks_api, aws_s3_bucket.loki_s3, aws_iam_role.loki_irsa_role, kubernetes_namespace.monitoring]
}

# Creating ConfigMap for Loki to be picked up as datasource by Grafana

resource "kubernetes_config_map" "grafana_loki_datasource" {
  metadata {
    name      = var.loki_configmap_name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_datasource = "1"  # looks for this label
      app                = "loki-stack"
    }
  }
  data = {
    "loki-datasource.yaml" = <<-EOF
          apiVersion: 1
          datasources:
          - name: Loki
            type: loki
            access: proxy
            url: "http://loki.monitoring.svc.cluster.local:3100"
            isDefault: false
            version: 1
            jsonData:
              httpHeaderName1: "X-Scope-OrgID"
            secureJsonData:
              httpHeaderValue1: "fastapi-production"
        EOF      
  }
  #depends_on = [null_resource.wait_for_eks_api, kubernetes_namespace.monitoring, module.loki-stack]
  depends_on = [null_resource.wait_for_eks_api, kubernetes_namespace.monitoring, helm_release.loki_stack]
}


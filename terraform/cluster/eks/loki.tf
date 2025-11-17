# Creating namespace
/*
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}*/

# Deploying Loki Helm Chart

module "loki-stack" {
  source  = "terraform-iaac/loki-stack/kubernetes"
  version = "1.3.1"

  # Provider type
  provider_type    = "aws" # Use an emptyDir volume to store logs temporarily
  create_namespace = false

  #  Add this override
  loki_docker_image = "grafana/loki:2.9.3"

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

/*
resource "null_resource" "delete_old_loki_secret" {
  provisioner "local-exec" {
    command = "kubectl delete secret loki-config -n ${var.loki_namespace} --ignore-not-found=true"
  }
  depends_on = [module.eks, module.loki-stack]
}


# Replace the old ConfigMap with this
resource "kubernetes_secret" "loki_config_override" {
  metadata {
    name      = "loki-config" # Must match the SecretName in StatefulSet
    namespace = var.loki_namespace
  }

  data = {
    # Loki expects base64-encoded content inside a Secret
    "loki.yaml" = templatefile("${path.module}/templates/loki_configmap.yaml", {
      bucket_name   = aws_s3_bucket.loki_s3.bucket
      bucket_region = var.aws_region
    })
  }

  type = "Opaque"

  depends_on = [null_resource.delete_old_loki_secret, module.loki-stack]
}


# Restart Loki after config change
resource "null_resource" "restart_loki" {
  provisioner "local-exec" {
    command = "kubectl rollout restart statefulset/loki -n ${var.loki_namespace}"
  }

  # Automatically trigger when loki.yaml template or S3 config changes
  triggers = {
    loki_config_hash = sha1(templatefile("${path.module}/templates/loki_configmap.yaml", {
      bucket_name   = aws_s3_bucket.loki_s3.bucket
      bucket_region = var.aws_region
    }))
  }

  depends_on = [kubernetes_secret.loki_config_override]
}


resource "null_resource" "delete_old_promtail_configmap" {
  provisioner "local-exec" {
    command = "kubectl delete configmap promtail-config -n ${var.loki_namespace} --ignore-not-found=true"
  }

  depends_on = [module.eks, module.loki-stack, null_resource.restart_loki]
}

resource "kubernetes_config_map" "promtail_config_override" {
  metadata {
    name      = "promtail-config"
    namespace = var.loki_namespace
  }

  data = {
    "promtail.yaml" = templatefile("${path.module}/templates/promtail_configmap.yaml", {
      loki_url  = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
      tenant_id = "fastapi-production"   # 👈 your new tenant ID
    })
  }

  depends_on = [null_resource.delete_old_promtail_configmap, module.loki-stack]
}

resource "null_resource" "restart_promtail" {
  provisioner "local-exec" {
    command = <<EOT
      Write-Host '⏳ Waiting 90 seconds for Loki to be ready...'
      Start-Sleep -Seconds 90
      Write-Host '🚀 Restarting Promtail DaemonSet now...'
      kubectl rollout restart daemonset/promtail -n ${var.loki_namespace}
    EOT
    interpreter = ["PowerShell", "-Command"]
  }

  depends_on = [kubernetes_config_map.promtail_config_override, null_resource.restart_loki]
}
*/


# Creating ConfigMap for Loki to be picked up as datasource by Grafana

resource "kubernetes_config_map" "grafana_loki_datasource" {
  metadata {
    name      = var.loki_configmap_name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_datasource = "1"
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
              httpHeaderValue1: "production"
        EOF      
  }
  depends_on = [null_resource.wait_for_eks_api, kubernetes_namespace.monitoring, module.loki-stack]
}


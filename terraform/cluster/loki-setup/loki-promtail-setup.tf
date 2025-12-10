

resource "null_resource" "delete_old_loki_secret" {
  provisioner "local-exec" {
    command = "kubectl delete secret loki-config -n ${var.loki_namespace} --ignore-not-found=true"
  }
}


# Replace Loki Secret

resource "kubernetes_secret" "loki_config_override" {
  metadata {
    name      = "loki-config" # Must match the SecretName in StatefulSet
    namespace = var.loki_namespace
  }

  data = {
    "loki.yaml" = templatefile("${path.module}/templates/loki_configmap.yaml", {
      bucket_name   = var.loki_s3_bucket_name
      bucket_region = var.aws_region
    })
  }

  type = "Opaque"
depends_on = [null_resource.delete_old_loki_secret]
}


# Restart Loki Statefulset after change

resource "null_resource" "restart_loki" {
  provisioner "local-exec" {
    command = "kubectl rollout restart statefulset/loki -n ${var.loki_namespace}"
  }

  # Automatically trigger when loki.yaml template or S3 config changes
  triggers = {
    loki_config_hash = sha1(templatefile("${path.module}/templates/loki_configmap.yaml", {
      bucket_name   = var.loki_s3_bucket_name
      bucket_region = var.aws_region
    }))
  }

  depends_on = [kubernetes_secret.loki_config_override]
}


resource "null_resource" "delete_old_promtail_configmap" {
  provisioner "local-exec" {
    command = "kubectl delete configmap promtail-config -n ${var.loki_namespace} --ignore-not-found=true"
  }

  depends_on = [null_resource.restart_loki]
}


# Replace Promatail ConfigMap

resource "kubernetes_config_map" "promtail_config_override" {
  metadata {
    name      = "promtail-config"
    namespace = var.loki_namespace
  }

  data = {
    "promtail.yaml" = templatefile("${path.module}/templates/promtail_configmap.yaml", {
      loki_url  = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
      tenant_id = "fastapi-production"   # new tenant ID
    })
  }

  depends_on = [null_resource.delete_old_promtail_configmap]
}

# Patch Promtail DaemonSet args to remove CLI client arg (so it uses the Config file only)
resource "null_resource" "fix_promtail_args" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOF
      set -euo pipefail

      echo "Patching promtail daemonset args to use only -config.file..."
      kubectl -n ${var.loki_namespace} patch daemonset promtail \
        --type='json' \
        -p='[{"op":"replace","path":"/spec/template/spec/containers/0/args","value":["-config.file=/etc/promtail/promtail.yaml"]}]'

      echo "Patched promtail args."
    EOF
  }

  # triggers: re-run when the promtail config template changes or Loki release changes
  triggers = {
    promtail_config_hash = sha1(templatefile("${path.module}/templates/promtail_configmap.yaml", {
      loki_url  = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
      tenant_id = "fastapi-production"
    }))
  }

  # must run after promtail configmap is created
  depends_on = [kubernetes_config_map.promtail_config_override]

}

# Restart Promtail Daemonset after change

resource "null_resource" "restart_promtail" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting 90 seconds for Loki to be ready..."
      sleep 90
      echo "Restarting Promtail DaemonSet now..."
      kubectl rollout restart daemonset/promtail -n ${var.loki_namespace}
    EOT
  }

  depends_on = [
    kubernetes_config_map.promtail_config_override,
    null_resource.restart_loki,
    null_resource.fix_promtail_args
  ]
}

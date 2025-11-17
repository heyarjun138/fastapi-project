# Helm release to deploy NGINX Helm Chart

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = true
  namespace        = var.ingress_nginx_namespace
  version          = var.ingress_nginx_chart_version #4.0.1 - old version
  timeout          = 600
  wait             = true

  values = [<<-EOF
  controller:
    service:
      type: LoadBalancer
      enabled: true
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
        service.beta.kubernetes.io/aws-load-balancer-internal: "${var.is_internal_nlb}" 
        service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "60"
  serviceAccount:
    create: true
    name: ingress-nginx
    annotations:
      eks.amazonaws.com/role-arn: "${aws_iam_role.ingress_nginx_irsa_role.arn}"

  EOF
  ]
  depends_on = [null_resource.wait_for_eks_api, aws_iam_role.ingress_nginx_irsa_role]
}


variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Default AWS region for the EKS layer"
}

variable "remote_s3_bucket_name" {
  type        = string
  default     = "tf-backend-bucket-capestone"
  description = "S3 bucket name that stores Terraform remote state files"
}

variable "remote_s3_bucket_region" {
  type        = string
  default     = "us-east-1"
  description = "Region where the remote backend S3 bucket is located"
}

variable "global_state_key" {
  type        = string
  default     = "infra/global/terraform.tfstate"
  description = "S3 object key path for the global layer state file"
}


variable "loki_role_name" {
  type        = string
  default     = "loki-irsa-role"
  description = "Loki role for IRSA"
}

variable "loki_chart_version" {
  type        = string
  default     = "5.44.0"
  description = "LOKI helm chart version"
}

variable "loki_s3_bucket_name" {
  type        = string
  default     = "my-loki-s3-bucket-fastapi"
  description = "Bucket name of S3 storage for Loki"
}

variable "promtail_chart_version" {
  type        = string
  default     = "6.15.0"
  description = "Promtail helm chart version"
}

variable "promtail_namespace" {
  type        = string
  default     = "monitoring"
  description = "Namespace where the promtail chart will be deployed"
}

variable "env" {
  type        = string
  default     = "Prod"
  description = "Environment"

}

variable "cluster_name" {
  type        = string
  default     = "my-cluster"
  description = "EKS cluster name"
}

variable "k8_version" {
  type        = string
  default     = "1.30"
  description = "Kubernetes version"
}
variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "Instance type of worker nodes"
}

variable "min_count" {
  type        = number
  default     = 1
  description = "Minimum nuber of nodes"
}

variable "desired_count" {
  type        = number
  default     = 2
  description = "Desired numer of nodes"
}

variable "max_count" {
  type        = number
  default     = 3
  description = "Maximum number of nodes"
}

variable "ingress_nginx_chart_version" {
  type        = string
  default     = "4.10.0"
  description = "NGINX helm chart version"
}

variable "ingress_nginx_namespace" {
  type        = string
  default     = "ingress-nginx"
  description = "Namespace where the ingress-nginx chart will be deployed"
}

variable "is_internal_nlb" {
  type        = bool
  default     = false
  description = "If true, creates an internal AWS NLB instead of internet-facing"
}

variable "cluster_autoscaler_chart_version" {
  type        = string
  default     = "9.29.0"
  description = "Cluster Autoscaler helm chart version"
}

variable "cluster_autoscaler_namespace" {
  type        = string
  default     = "kube-system"
  description = "Namespace where the cluster autoscaler chart will be deployed"
}

variable "loki_iam_policy_name" {
  type        = string
  default     = "loki_s3_policy"
  description = "IAM policy name for Loki to access S3 Bucket"
}

variable "cluster_autoscaler_iam_policy_name" {
  type        = string
  default     = "cluster_autoscaler_policy"
  description = "IAM policy name for Cluster Autoscaler"
}

variable "nginx_iam_policy_name" {
  type        = string
  default     = "nginx-lb-policy"
  description = "IAM policy name for NGINX"
}

variable "loki_namespace" {
  type        = string
  default     = "monitoring"
  description = "Namespace where the loki chart will be deployed"
}

variable "loki_configmap_name" {
  type        = string
  default     = "loki-datasource"
  description = "Name of the ConfigMap for Loki to be picked up as datasource by Grafana"
}
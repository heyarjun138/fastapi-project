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


variable "loki_s3_bucket_name" {
  type        = string
  default     = "my-loki-s3-bucket-fastapi"
  description = "Bucket name of S3 storage for Loki"
}


variable "env" {
  type        = string
  default     = "Prod"
  description = "Environment"

}

variable "loki_namespace" {
  type        = string
  default     = "monitoring"
  description = "Namespace where the loki chart will be deployed"
}

variable "eks_cluster_name" {
  type = string
  default = "my-cluster"
  description = "EKS Cluster Name"
}
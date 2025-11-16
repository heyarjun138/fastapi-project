variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region for Global Layer"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for VPC"
}

variable "subnet_count" {
  type        = number
  default     = 2
  description = "Subnet count for both public and private"
}

variable "cluster_name" {
  type        = string
  default     = "my-cluster"
  description = "Name of the EKS Cluster"
}

variable "env" {
  type        = string
  default     = "prod"
  description = "Environment name"
}

variable "project" {
  type        = string
  default     = "capestone"
  description = "Project name"
}

variable "s3_remote_backend" {
  type = string
}
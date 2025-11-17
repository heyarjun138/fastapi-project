output "loki_bucket" {
  value       = aws_s3_bucket.loki_s3.bucket
  description = "loki bucket name"
}

output "oidc" {
  value = module.eks.oidc_provider
}
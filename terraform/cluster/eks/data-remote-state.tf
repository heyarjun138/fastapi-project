# Data Source to fetch global state

data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = var.remote_s3_bucket_name
    key    = var.global_state_key
    region = var.remote_s3_bucket_region
  }
}

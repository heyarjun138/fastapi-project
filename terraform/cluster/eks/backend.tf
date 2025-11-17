terraform {
  backend "s3" {
    bucket       = "tf-backend-bucket-capestone"
    key          = "infra/cluster/eks/terraform.tfstate"
    region       = "us-east-1" #Must match the bucket region
    use_lockfile = true        #Enabling S3 State Locking
    encrypt      = true
  }
}
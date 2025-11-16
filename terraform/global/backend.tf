terraform {
  backend "s3" {
    bucket       = "tf-backend-bucket-capestone"
    key          = "infra/global/terraform.tfstate"
    region       = "us-east-1" #Must match the bucket region
    use_lockfile = true        #Enabling S3 State Locking
    encrypt      = true
  }
}
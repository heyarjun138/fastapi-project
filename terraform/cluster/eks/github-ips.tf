# Fetch GitHub Actions Runner IP ranges 

data "http" "github_ips" {
  url = "https://api.github.com/meta"

  # Optional: forces Terraform to fetch fresh data each time
  request_headers = {
    Accept = "application/json"
  }
}

# Extract only IPv4 CIDRs used by runners

locals {
  # GitHub returns IPv4 + IPv6. EKS only accepts IPv4.
  github_actions_ips = [
    for cidr in jsondecode(data.http.github_ips.body).actions :
    cidr if can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/", cidr))
  ]
}

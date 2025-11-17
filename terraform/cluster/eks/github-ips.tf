# Fetch GitHub Actions Runner IP ranges 
data "http" "github_ips" {
  url = "https://api.github.com/meta"

  request_headers = {
    Accept = "application/json"
  }
}

# Extract only IPv4 CIDRs used by runners
locals {
  github_actions_ips = [
    for cidr in jsondecode(data.http.github_ips.response_body).actions :
    cidr if can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/", cidr))
  ]
}

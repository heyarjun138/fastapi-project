# IAM Policy for the Loki Role

resource "aws_iam_policy" "loki_s3_policy" {
  name        = var.loki_iam_policy_name
  path        = "/"
  description = "Policy for Loki to store and manage logs in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BucketLevelAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
          "s3:HeadBucket",
          "s3:ListObjects",
          "s3:ListObjectsV2"
        ]
        Resource = aws_s3_bucket.loki_s3.arn
      },
      {
        Sid    = "ObjectLevelAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = "${aws_s3_bucket.loki_s3.arn}/*"
      }
    ]
  })
}



# IAM Policy for the Cluster Autoscaler Role

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = var.cluster_autoscaler_iam_policy_name
  path        = "/"
  description = "Policy for cluster autoscaler"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ASGAccess",
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeTags"
        ],
        Resource = "*" # Needed for all ASGs in the cluster
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeLaunchTemplateVersions" # Needed to read Launch Template details
        ],
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for the NGINX Role

resource "aws_iam_policy" "nginx_lb_policy" {
  name        = var.nginx_iam_policy_name
  description = "Policy for NGINX Ingress Controller to manage AWS Load Balancers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:Describe*",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "iam:CreateServiceLinkedRole",
          "iam:GetServerCertificate",
          "iam:ListServerCertificates",
          "tag:GetResources",
          "tag:TagResources"
        ]
        Resource = "*"
      }
    ]
  })
}

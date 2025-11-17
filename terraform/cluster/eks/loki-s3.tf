resource "aws_s3_bucket" "loki_s3" {
  bucket        = var.loki_s3_bucket_name #must be globally unique, make sure to check it
  force_destroy = true
  tags = {
    Name        = var.loki_s3_bucket_name
    Environment = var.env
  }
}

resource "aws_s3_bucket_versioning" "loki_s3_versioning" {
  bucket = aws_s3_bucket.loki_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki_s3_sse_encryption" {
  bucket = aws_s3_bucket.loki_s3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "loki_bucket_config" {
  bucket = aws_s3_bucket.loki_s3.id

  rule {
    id = "expired-logs"

    filter {
      prefix = "" # empty prefix means "all objects"
    }

    expiration {
      days = 90
    }

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_loki_to_s3" {
  bucket = aws_s3_bucket.loki_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allowing loki to access S3"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.loki_irsa_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          "${aws_s3_bucket.loki_s3.arn}",
          "${aws_s3_bucket.loki_s3.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "loki_s3_access_block" {
  bucket = aws_s3_bucket.loki_s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


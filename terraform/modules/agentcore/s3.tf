# S3 bucket for deployment package (only created if bucket_name is not provided)
resource "aws_s3_bucket" "deployment" {
  count  = local.create_bucket ? 1 : 0
  bucket = local.bucket_name

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "deployment" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.deployment[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deployment" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.deployment[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "deployment" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.deployment[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload deployment package to S3
resource "aws_s3_object" "deployment_package" {
  bucket = local.create_bucket ? aws_s3_bucket.deployment[0].id : var.bucket_name
  key    = local.object_key
  source = local.package_zip_path

  # Trigger re-upload when source changes
  source_hash = local.source_hash

  # Ensure packaging is complete before upload
  depends_on = [null_resource.package_code]

  tags = local.tags
}


# S3 bucket for agent outputs (research documents, findings, reports)
# This bucket stores all intermediate and final outputs from agent sessions

# Create bucket only when create_outputs_bucket is true AND no custom bucket name provided
resource "aws_s3_bucket" "outputs" {
  count  = local.create_outputs_bucket_resource ? 1 : 0
  bucket = local.outputs_bucket_name

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "outputs" {
  count  = local.create_outputs_bucket_resource ? 1 : 0
  bucket = aws_s3_bucket.outputs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "outputs" {
  count  = local.create_outputs_bucket_resource ? 1 : 0
  bucket = aws_s3_bucket.outputs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "outputs" {
  count  = local.create_outputs_bucket_resource ? 1 : 0
  bucket = aws_s3_bucket.outputs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "outputs" {
  count  = local.create_outputs_bucket_resource && var.outputs_retention_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.outputs[0].id

  rule {
    id     = "expire-old-outputs"
    status = "Enabled"

    expiration {
      days = var.outputs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.outputs_retention_days
    }
  }
}

# Data source for existing outputs bucket (if provided)
data "aws_s3_bucket" "outputs_provided" {
  count  = var.create_outputs_bucket && var.outputs_bucket_name != null ? 1 : 0
  bucket = var.outputs_bucket_name
}


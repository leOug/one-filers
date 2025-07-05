terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "random" {
}

variable "aws_region" {
  description = "The AWS region that I am working on"
  type = string
  default = "eu-north-1"
}

variable "very-important-prefixes" {
  description = "A list of prefixes that will be created in the very important bucket"
  type = list(string)
  default = ["configs","important-configs"]
}

resource "random_uuid" "very-important-uuid" {
}

resource "aws_s3_bucket" "very-important-s3-bucket" {
  bucket = "very-important-bucket-${random_uuid.very-important-uuid.result}"

  tags = {
    Name        = "very-important-bucket"
    Project = "important-files"
  }
}

resource "aws_s3_object" "very-important-prefixes" {
  depends_on = [aws_s3_bucket.very-important-s3-bucket]

  for_each = toset(var.very-important-prefixes)
  bucket = aws_s3_bucket.very-important-s3-bucket.id
  key = "${each.key}/"
  content_type = "application/x-directory"
}

resource "aws_s3_bucket_versioning" "very-important-versioned-bucket" {
  bucket = aws_s3_bucket.very-important-s3-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "very-important-ownership-controls" {
  bucket = aws_s3_bucket.very-important-s3-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "very-important-private-bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.very-important-ownership-controls]

  bucket = aws_s3_bucket.very-important-s3-bucket.id
  acl = "private"
}

output "very-important-bucket-name" {
  value = aws_s3_bucket.very-important-s3-bucket.bucket
}

output "very-important-bucket-arn" {
  value = aws_s3_bucket.very-important-s3-bucket.arn
}

output "very-important-bucket-regional-domain-name" {
  value = aws_s3_bucket.very-important-s3-bucket.bucket_regional_domain_name
}

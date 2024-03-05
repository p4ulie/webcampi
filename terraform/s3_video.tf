resource "aws_s3_bucket" "video" {
  bucket = var.aws_bucket_video
  tags   = var.aws_tags
}

resource "aws_s3_bucket_ownership_controls" "video" {
  bucket = aws_s3_bucket.video.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "video" {
  statement {
    sid = "Read file"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.video.arn}/*",
    ]
  }

  statement {
    sid = "List files"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.video.arn,
    ]
  }

  statement {
    sid = "CloudFront access"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.video.arn}/*",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:Referer"
      values   = ["${aws_cloudfront_distribution.video.domain_name}"]
    }

  }

}

resource "aws_s3_bucket_policy" "video" {
  bucket = aws_s3_bucket.video.id
  policy = data.aws_iam_policy_document.video.json
}

resource "aws_s3_bucket_website_configuration" "video" {
  bucket = aws_s3_bucket.video.id

  index_document {
    suffix = "latest.html"
  }

  #  error_document {
  #    key = "error.html"
  #  }

  #  routing_rule {
  #    condition {
  #      key_prefix_equals = "docs/"
  #    }
  #    redirect {
  #      replace_key_prefix_with = "documents/"
  #    }
  #  }
}

resource "aws_s3_bucket_versioning" "video" {
  bucket = aws_s3_bucket.video.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "storage_class" {
  bucket = aws_s3_bucket.video.id

  rule {
    id = "storage_class_change_for_images_2024"

    filter {
      prefix = "2024/"
    }

    transition {
      days          = 3
      storage_class = "GLACIER_IR"
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "video" {
  bucket = aws_s3_bucket.video.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3_access_log/"
}

resource "aws_s3_object" "robots" {
  bucket = aws_s3_bucket.video.id
  key    = "robots.txt"
  source = "robots.txt"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("robots.txt")
}

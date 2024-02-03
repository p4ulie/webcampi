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
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.video.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "${aws_s3_bucket.video.arn}",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"]
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
    id = "storage_class_change_for_images_2022"

    filter {
      prefix = "2022/"
    }

    transition {
      days          = 3
      storage_class = "GLACIER_IR"
    }

    status = "Enabled"
  }

  rule {
    id = "storage_class_change_for_images_2023"

    filter {
      prefix = "2023/"
    }

    transition {
      days          = 3
      storage_class = "GLACIER_IR"
    }

    status = "Enabled"
  }

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

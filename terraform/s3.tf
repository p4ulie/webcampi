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

#Using S3 bucket policy to controll access, ACL not needed here

#resource "aws_s3_bucket_public_access_block" "video" {
#  bucket = aws_s3_bucket.video.id
#
#  block_public_acls       = false
#  block_public_policy     = false
#  ignore_public_acls      = false
#  restrict_public_buckets = false
#}

#resource "aws_s3_bucket_acl" "video" {
#  depends_on = [
#    aws_s3_bucket_ownership_controls.video,
##    aws_s3_bucket_public_access_block.video,
#  ]
#
#  bucket = aws_s3_bucket.video.id
#  acl    = "public-read"
#}

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

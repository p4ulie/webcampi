data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "video_bucket_full_access" {
  statement {
    sid = "S3AdditionalAccess"

    actions = [
      "s3:PutStorageLensConfiguration",
      "s3:PutAccountPublicAccessBlock",
      "s3:PutAccessPointPublicAccessBlock",
      "s3:ListStorageLensConfigurations",
      "s3:ListMultiRegionAccessPoints",
      "s3:ListJobs",
      "s3:ListAllMyBuckets",
      "s3:ListAccessPointsForObjectLambda",
      "s3:ListAccessPoints",
      "s3:GetAccountPublicAccessBlock",
      "s3:GetAccessPoint",
      "s3:CreateJob"
    ]

    resources = ["*"]
  }
  statement {
    sid = "S3VideoBucketFullAccess"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.video.arn,
      "${aws_s3_bucket.video.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "video_bucket_full_access" {
  name        = "webcampi_s3_full"
  path        = "/"
  description = ""

  policy = data.aws_iam_policy_document.video_bucket_full_access.json

  tags = var.aws_tags
}

resource "aws_iam_role" "convert_video_full_access" {
  name               = "convert_instance_s3_access"
  description        = "Allows EC2 to access S3 on your behalf."
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.aws_tags
}

resource "aws_iam_role_policy_attachment" "convert_video_full_access" {
  role = aws_iam_role.convert_video_full_access.name

  policy_arn = aws_iam_policy.video_bucket_full_access.arn
}

resource "aws_iam_role" "lambda_convert_image_to_video" {
  name               = "lambda_convert_image_to_video"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_convert_image_to_video_s3_access" {
  role = aws_iam_role.lambda_convert_image_to_video.name

  policy_arn = aws_iam_policy.video_bucket_full_access.arn
}

data "aws_iam_policy_document" "lambda_logs" {
  statement {
    sid = "CreateLogGroup"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
    sid = "LogStreamAndEvents"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/convert_image_to_video:*"]
  }
}

resource "aws_iam_policy" "lambda_logs" {
  name        = "lambda_logs"
  path        = "/"
  description = ""

  policy = data.aws_iam_policy_document.lambda_logs.json

  tags = var.aws_tags
}

resource "aws_iam_role_policy_attachment" "lambda_convert_image_to_video_logs" {
  role = aws_iam_role.lambda_convert_image_to_video.name

  policy_arn = aws_iam_policy.lambda_logs.arn
}

data "aws_iam_policy_document" "lambda_invoke" {
  statement {
    sid = "S3InvokeLambda"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = ["arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:*"]
  }
}

resource "aws_iam_policy" "lambda_invoke" {
  name        = "lambda_invoke"
  path        = "/"
  description = ""

  policy = data.aws_iam_policy_document.lambda_invoke.json

  tags = var.aws_tags
}

resource "aws_iam_role_policy_attachment" "lambda_invoke" {
  role = aws_iam_role.lambda_convert_image_to_video.name

  policy_arn = aws_iam_policy.lambda_invoke.arn
}

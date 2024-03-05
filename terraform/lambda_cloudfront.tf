# lambda function generate_video_page
data "archive_file" "lambda_basic_auth" {
  type        = "zip"
  source_file = "lambda/lambda_basic_auth.js"
  output_path = "lambda/lambda_basic_auth.zip"
}

resource "aws_lambda_function" "lambda_basic_auth" {
  provider = aws.aws_cloudfront_related  # Specify the provider alias for this resource

  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda/lambda_basic_auth.zip"
  function_name = "lambda_basic_auth"
  description   = "Lambda@Edge function for basic HTTP auth"
  role          = aws_iam_role.lambda_basic_auth.arn
  handler       = "lambda_basic_auth.handler"
  publish       = true  # This triggers the creation of a new version each time the function is updated

  source_code_hash = data.archive_file.lambda_basic_auth.output_base64sha256

  runtime = "nodejs20.x"

  memory_size = 128
  timeout     = 5
}

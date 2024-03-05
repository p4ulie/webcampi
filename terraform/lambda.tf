resource "aws_lambda_layer_version" "lambda_layer_ffmpeg" {
  layer_name               = "lambda_layer_ffmpeg"
  description              = "FFMpeg binary for image/video transcoding"
  compatible_architectures = ["x86_64"]
  compatible_runtimes      = ["python3.12"]

  s3_bucket = "p4ulie-lambda-layers"
  s3_key    = "lambda_layer_ffmpeg_payload.zip"
}

# lambda function convert_image_to_video
data "archive_file" "convert_image_to_video" {
  type        = "zip"
  source_file = "lambda/convert_image_to_video.py"
  output_path = "lambda/convert_image_to_video_payload.zip"
}

resource "aws_lambda_function" "convert_image_to_video" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda/convert_image_to_video_payload.zip"
  function_name = "convert_image_to_video"
  role          = aws_iam_role.lambda_convert_image_to_video.arn
  handler       = "convert_image_to_video.lambda_handler"

  source_code_hash = data.archive_file.convert_image_to_video.output_base64sha256

  runtime = "python3.12"
  layers  = [aws_lambda_layer_version.lambda_layer_ffmpeg.arn]

  memory_size = 1536
  timeout     = 900

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
  }
}

# lambda function combine_videos
data "archive_file" "combine_videos" {
  type        = "zip"
  source_file = "lambda/combine_videos.py"
  output_path = "lambda/combine_videos_payload.zip"
}

resource "aws_lambda_function" "combine_videos" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda/combine_videos_payload.zip"
  function_name = "combine_videos"
  role          = aws_iam_role.lambda_convert_image_to_video.arn
  handler       = "combine_videos.lambda_handler"

  source_code_hash = data.archive_file.combine_videos.output_base64sha256

  runtime = "python3.12"
  layers  = [aws_lambda_layer_version.lambda_layer_ffmpeg.arn]

  memory_size = 1536
  timeout     = 900

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
  }
}

# lambda function convert_day
data "archive_file" "convert_day" {
  type        = "zip"
  source_file = "lambda/convert_day.py"
  output_path = "lambda/convert_day_payload.zip"
}

resource "aws_lambda_function" "convert_day" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda/convert_day_payload.zip"
  function_name = "convert_day"
  role          = aws_iam_role.lambda_convert_image_to_video.arn
  handler       = "convert_day.lambda_handler"

  source_code_hash = data.archive_file.convert_day.output_base64sha256

  runtime = "python3.12"

  memory_size = 256
  timeout     = 900

  ephemeral_storage {
    size = 512 # Min 512 MB and the Max 10240 MB
  }
}

# lambda function generate_video_page
data "archive_file" "generate_video_page" {
  type        = "zip"
  source_file = "lambda/generate_video_page.py"
  output_path = "lambda/generate_video_page.zip"
}

resource "aws_lambda_function" "generate_video_page" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda/generate_video_page.zip"
  function_name = "generate_video_page"
  role          = aws_iam_role.lambda_convert_image_to_video.arn
  handler       = "generate_video_page.lambda_handler"

  source_code_hash = data.archive_file.generate_video_page.output_base64sha256

  runtime = "python3.12"

  memory_size = 256
  timeout     = 900

  ephemeral_storage {
    size = 512 # Min 512 MB and the Max 10240 MB
  }
}

resource "aws_lambda_layer_version" "lambda_layer_ffmpeg" {
  layer_name               = "lambda_layer_ffmpeg"
  description              = "FFMpeg binary for image/video transcoding"
  compatible_architectures = ["x86_64"]
  compatible_runtimes      = ["python3.12"]

  s3_bucket = "p4ulie-lambda-layers"
  s3_key    = "lambda_layer_ffmpeg_payload.zip"
}

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
  role          = aws_iam_role.convert_image_to_video.arn
  handler       = "lambda_handler"

  source_code_hash = data.archive_file.convert_image_to_video.output_base64sha256

  runtime = "python3.12"
  layers = [aws_lambda_layer_version.lambda_layer_ffmpeg.arn]

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
  }

  #  environment {
  #    variables = {
  #      foo = "bar"
  #    }
  #  }

}

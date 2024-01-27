resource "aws_cloudwatch_log_group" "convert_image_to_video" {
  name = "/aws/lambda/convert_image_to_video"

  tags = var.aws_tags
}

resource "aws_cloudwatch_log_group" "convert_day" {
  name = "/aws/lambda/convert_day"

  tags = var.aws_tags
}

resource "aws_cloudwatch_log_group" "combine_videos" {
  name = "/aws/lambda/combine_videos"

  tags = var.aws_tags
}

resource "aws_cloudwatch_log_group" "generate_video_page" {
  name = "/aws/lambda/generate_video_page"

  tags = var.aws_tags
}

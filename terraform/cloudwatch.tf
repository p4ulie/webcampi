resource "aws_cloudwatch_log_group" "convert_image_to_video" {
  name = "/aws/lambda/convert_image_to_video"

  tags = var.aws_tags
}

resource "aws_cloudwatch_log_group" "convert_day" {
  name = "/aws/lambda/convert_day"

  tags = var.aws_tags
}

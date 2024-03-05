resource "aws_cloudwatch_event_rule" "convert_day_schedule" {
  name                = "convert_day_schedule"
  description         = "Schedule for Lambda Function to run conversion every day"
  schedule_expression = "cron(15 3 * * ? *)"
}

resource "aws_cloudwatch_event_target" "convert_day_schedule" {
  rule      = aws_cloudwatch_event_rule.convert_day_schedule.name
  target_id = "convert_day"
  arn       = aws_lambda_function.convert_day.arn
}

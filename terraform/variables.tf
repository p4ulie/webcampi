variable "aws_region" {
  type        = string
  description = "Region to work on."
  default     = "eu-central-1"
}

variable "aws_tags" {
  type        = map(string)
  description = "Tags to add to all resources."
  default     = {}
}

variable "aws_bucket_video" {
  type        = string
  description = "Name of the bucket to store images/video."
  default     = "webcampi"
}

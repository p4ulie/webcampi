resource "aws_cloudfront_origin_access_control" "video" {
  name                              = "example"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "video" {
  origin {
    domain_name              = aws_s3_bucket.video.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.video.id
    origin_id                = aws_s3_bucket.video.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Webcampi"
  default_root_object = "latest.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "CloudFront"
  }

#  aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.video.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    # Add Lambda@Edge function to the viewer request stage
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.lambda_basic_auth.qualified_arn
    }
  }

#  # Cache behavior with precedence 0
#  ordered_cache_behavior {
#    path_pattern     = "/content/immutable/*"
#    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#    cached_methods   = ["GET", "HEAD", "OPTIONS"]
#    target_origin_id = aws_s3_bucket.video.id
#
#    forwarded_values {
#      query_string = false
#      headers      = ["Origin"]
#
#      cookies {
#        forward = "none"
#      }
#    }
#
#    min_ttl                = 0
#    default_ttl            = 86400
#    max_ttl                = 31536000
#    compress               = true
#    viewer_protocol_policy = "redirect-to-https"
#  }
#
#  # Cache behavior with precedence 1
#  ordered_cache_behavior {
#    path_pattern     = "/content/*"
#    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#    cached_methods   = ["GET", "HEAD"]
#    target_origin_id = aws_s3_bucket.video.id
#
#    forwarded_values {
#      query_string = false
#
#      cookies {
#        forward = "none"
#      }
#    }
#
#    min_ttl                = 0
#    default_ttl            = 3600
#    max_ttl                = 86400
#    compress               = true
#    viewer_protocol_policy = "redirect-to-https"
#  }

#  price_class = "PriceClass_200"
#
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = var.aws_tags

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

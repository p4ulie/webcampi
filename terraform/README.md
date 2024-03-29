```terraform
terraform {
  backend "s3" {
    bucket         = "<bucket-name>"
    key            = "terraform.state"
    region         = var.aws_region
    dynamodb_table = "terraform-lock"
  }
}
```

```terraform
resource "aws_dynamodb_table" "terraform-lock" {
name = "terraform-lock"
hash_key = "LockID"
read_capacity = 20
write_capacity = 20

attribute {
name = "LockID"
type = "S"
}
}
```

# Video processing in Lambda

https://aws.plainenglish.io/automated-video-processing-with-aws-lambda-and-ffmpeg-51ea9c79aa2a

(Generated partially by ChatGPT)

Creating Lambda layers involves bundling additional code and dependencies with your function. For a layer containing Python, FFmpeg, and x265 codec packages, you'll need to prepare these components and structure them properly for Lambda.

Here are the general steps to create a Lambda layer:

1. Prepare the Layer Structure:
   Python Dependencies:
   Create a python directory that includes any additional Python libraries your function needs. You can install them using pip and copy them into this directory.
   FFmpeg and x265:
   Create a bin directory to contain the binaries. Place the FFmpeg and x265 codec binaries within this directory.
2. Package the Layer:
   Zip the python and bin directories separately.
3. Create the Layer in AWS Lambda:
   In the AWS Management Console, navigate to Lambda.
   Go to the Layers section and click "Create layer."
   Upload the zip files you created for Python dependencies and FFmpeg/x265 binaries separately.
   Provide a meaningful name and description for your layer.
4. Attach the Layer to your Lambda Function:
   In your Lambda function settings, you'll find a section for layers.
   Add the created layers to your Lambda function.
   Additional Considerations:
   Lambda Function Size Limit:

Ensure that the size of your Lambda function, including layers, doesn't exceed the size limit.
Path and Execution Permissions:

Make sure the paths to FFmpeg and x265 binaries are correctly set in your Lambda code within the layer. Also, ensure the Lambda function has execution permissions for these binaries.
Testing:

After creating the layers and attaching them to your Lambda function, test the function thoroughly to ensure FFmpeg and x265 codec are accessible and functioning correctly.
Preparing these layers might involve different methods based on the source of FFmpeg and x265 codec binaries. You might compile these from source compatible with Lambda's execution environment or leverage precompiled binaries specifically built for Lambda environments.

Remember, packaging FFmpeg and x265 codec might increase the layer's size significantly, potentially affecting Lambda's cold start time and the overall performance. Consider optimizing the layer size and
Lambda's execution environment accordingly.

## Lambda test event

```json
{
  "s3_parameters": {
    "bucket_directory_year": "2023",
    "bucket_directory_month": "12",
    "bucket_directory_day": "01",
    "bucket_directory_hour": "11"
  }
}
```

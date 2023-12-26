# import subprocess
import boto3
import os
import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    s3_parameters = event['s3_parameters']

    # Replace with your bucket name and source/destination directories
    if 'bucket_name' in s3_parameters.keys():
        s3_bucket_name = s3_parameters['bucket_name']
    else:
        s3_bucket_name ='webcampi'

    s3_date_year = s3_parameters['bucket_directory_year']
    s3_date_month = s3_parameters['bucket_directory_month']
    s3_date_day = s3_parameters['bucket_directory_day']

    s3_source_directory = f'{s3_date_year}/{s3_date_month}/{s3_date_day}/'

    if 'bucket_directory_destination' in s3_parameters.keys():
        s3_destination_directory = s3_parameters['bucket_directory_destination']
    else:
        s3_destination_directory = 'video_test'

    lambda_client = boto3.client('lambda')
    lambda_function_name = "convert_image_to_video"

    # List subdirectories within the base directory
    # s3_client = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(s3_bucket_name)

    for obj in bucket.objects.filter(Prefix=s3_source_directory):
        if obj.key != s3_source_directory:
            logger.info(f'Invoking lambda function for {obj.key}')
            event = {
                "s3_parameters": {
                    "bucket_directory_year": s3_date_year,
                    "bucket_directory_month": s3_date_month,
                    "bucket_directory_day": s3_date_day,
                    "bucket_directory_hour": obj.key.split('/')[-1],
                    "bucket_directory_destination": s3_destination_directory
                }
            }
            logger.info(f'Invoking lambda function {lambda_function_name} for {event}')
            print(event)
            # response = lambda_client.invoke(
            #     FunctionName=lambda_function_name,
            #     Payload=json.dumps(event),
            # )

    return {
        'statusCode': 200,
        'body': 'Video transcoding complete.'
    }

# if __name__ == "__main__":
#     event = {
#         "s3_parameters": {
#             "bucket_directory_year": "2023",
#             "bucket_directory_month": "12",
#             "bucket_directory_day": "01",
#             "bucket_directory_destination": "video_test"
#         }
#     }
#     lambda_handler(event, "")

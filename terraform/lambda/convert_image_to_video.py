import subprocess
import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

log_formatter = logging.Formatter('%(message)s')

log_stream = logging.StreamHandler()
log_stream.setLevel(logging.INFO)
log_stream.setFormatter(log_formatter)
logger.addHandler(log_stream)

def download_from_s3(bucket_name, s3_directory, local_directory):
    s3 = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(bucket_name)

    logger.info(f'Download images from {s3_directory}')

    for obj in bucket.objects.filter(Prefix=s3_directory):
        if obj.key.endswith('.jpg'):
            file_name = obj.key.split('/')[-1]
            file_path = os.path.join(local_directory, file_name)
            logger.info(f'Download image {obj.key} to {file_path}')
            bucket.download_file(obj.key, file_path)

def upload_to_s3(bucket_name, local_file_path, s3_directory, s3_file_name,content_type='video/mp4'):
    s3_client = boto3.client('s3')
    logger.info(f'Uploading the video {local_file_path} to {s3_directory}/{s3_file_name}')
    s3_client.upload_file(local_file_path, bucket_name, f'{s3_directory}/{s3_file_name}', ExtraArgs={'ContentType': content_type})

def lambda_handler(event, context):
    s3_parameters = event['s3_parameters']

    logger.info(f'Event data: {event}')

    # Replace with your bucket name and source/destination directories
    if 'bucket_name' in s3_parameters.keys():
        s3_bucket_name = s3_parameters['bucket_name']
    else:
        s3_bucket_name ='webcampi'

    s3_date_year = s3_parameters['bucket_directory_year']
    s3_date_month = s3_parameters['bucket_directory_month']
    s3_date_day = s3_parameters['bucket_directory_day']
    s3_date_hour = s3_parameters['bucket_directory_hour']

    s3_source_directory = f'{s3_date_year}/{s3_date_month}/{s3_date_day}/{s3_date_hour}/'

    if 'bucket_directory_destination' in s3_parameters.keys():
        s3_destination_directory = s3_parameters['bucket_directory_destination']
    else:
        s3_destination_directory = 'video_processing'

    image_directory = '/tmp/images'
    output_directory = '/tmp/output'
    output_file_name = f'{s3_date_year}_{s3_date_month}_{s3_date_day}_{s3_date_hour}.mp4'  # Name for the output video file

    # Ensure the local directories exist
    os.makedirs(image_directory, exist_ok=True)
    os.makedirs(output_directory, exist_ok=True)

    # List subdirectories within the base directory
    s3 = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(s3_bucket_name)

    for obj in bucket.objects.filter(Prefix=s3_source_directory):
        if obj.key != s3_source_directory:
            download_from_s3(s3_bucket_name, obj.key, os.path.join(image_directory))

    # Change directory to access the source files
    os.chdir(image_directory)

    logger.info('Encode the video')
    # Use FFmpeg to create a video from images in the directory
    subprocess.run(['/opt/ffmpeg/ffmpeg', '-y', '-framerate', '30', '-pattern_type', 'glob', '-i', '*.jpg', '-c:v', 'libx265', '-vtag', 'hvc1', '-pix_fmt', 'yuv420p', os.path.join(output_directory, output_file_name)], check=True)

    logger.info(f'Upload the video {os.path.join(output_directory, output_file_name)}')
    # Upload the resulting video to S3
    upload_to_s3(
        bucket_name=s3_bucket_name,
        local_file_path=os.path.join(output_directory, output_file_name),
        s3_directory=s3_destination_directory,
        s3_file_name=output_file_name
    )

    return {
        'statusCode': 200,
        'body': 'Video transcoding complete.'
    }

if __name__ == "__main__":
    event = {
        "s3_parameters": {
            "bucket_directory_year": "2024",
            "bucket_directory_month": "01",
            "bucket_directory_day": "24",
            "bucket_directory_hour": "00"
        }
    }
    lambda_handler(event, "")

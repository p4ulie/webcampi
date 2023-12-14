import subprocess
import boto3
import os
import tempfile
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def download_from_s3(bucket_name, s3_directory, local_directory):
    s3 = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(bucket_name)

    for obj in bucket.objects.filter(Prefix=s3_directory):
        if obj.key.endswith('.jpg'):
            file_name = obj.key.split('/')[-1]
            file_path = os.path.join(local_directory, file_name)
            bucket.download_file(obj.key, file_path)

def upload_to_s3(bucket_name, local_file_path, s3_directory, s3_file_name):
    s3 = boto3.client('s3')
    s3.upload_file(local_file_path, bucket_name, f"{s3_directory}/{s3_file_name}")

def lambda_handler(event, context):
    # Replace with your bucket name and source/destination directories
    s3_bucket_name = 'webcampi'

    # s3_date_year = '2023'
    s3_date_year = event.get('sourceParameters',{}).get('year','n/a')
    # s3_date_month = '12'
    s3_date_month = event.get('sourceParameters',{}).get('month','n/a')
    # s3_date_day = '01'
    s3_date_day = event.get('sourceParameters',{}).get('day','n/a')

    s3_source_directory = f'{s3_date_year}/{s3_date_month}/{s3_date_day}/'
    s3_destination_directory = 'video'

    image_directory = '/tmp/images'
    output_directory = '/tmp/output'
    output_file_name = f'{s3_date_year}_{s3_date_month}_{s3_date_day}_test.mp4'  # Name for the output video file

    # Ensure the local directories exist
    os.makedirs(image_directory, exist_ok=True)
    os.makedirs(output_directory, exist_ok=True)

    # List subdirectories within the base directory
    s3 = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(s3_bucket_name)

    for obj in bucket.objects.filter(Prefix=s3_source_directory):
        if obj.key != s3_source_directory:
            subdirectory = obj.key[len(s3_source_directory):].split('/')[0]
            logger.info(f'Download image {obj.key}')
            download_from_s3(s3_bucket_name, obj.key, os.path.join(image_directory))

    # Change directory to access the source files
    os.chdir(image_directory)

    logger.info('Encode the video')
    # Use FFmpeg to create a video from images in the directory
    subprocess.run(['ffmpeg', '-framerate', '30', '-pattern_type', 'glob', '-i', '*.jpg', '-c:v', 'libx265', '-pix_fmt', 'yuv420p', os.path.join(output_directory, output_file_name)], check=True)

    logger.info('Upload the video {os.path.join(output_directory, output_file_name)}')
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
    lambda_handler("", "")

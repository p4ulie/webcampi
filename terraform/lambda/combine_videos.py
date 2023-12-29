import subprocess
import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def download_from_s3(bucket_name, s3_directory, local_directory):
    s3 = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(bucket_name)

    for obj in bucket.objects.filter(Prefix=s3_directory):
        if obj.key.endswith('.mp4'):
            file_name = obj.key.split('/')[-1]
            file_path = os.path.join(local_directory, file_name)
            bucket.download_file(obj.key, file_path)

def upload_to_s3(bucket_name, local_file_path, s3_directory, s3_file_name):
    s3_client = boto3.client('s3')
    s3_client.upload_file(local_file_path, bucket_name, f"{s3_directory}/{s3_file_name}")

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

    s3_source_directory = f'video_test/{s3_date_year}_{s3_date_month}_{s3_date_day}/'

    if 'bucket_directory_destination' in s3_parameters.keys():
        s3_destination_directory = s3_parameters['bucket_directory_destination']
    else:
        s3_destination_directory = 'video_test'

    source_video_directory = '/tmp/source_videos'
    output_directory = '/tmp/video_output'
    output_file_name = f'{s3_date_year}_{s3_date_month}_{s3_date_day}_combined.mp4'  # Name for the output video file

    # Ensure the local directories exist
    os.makedirs(source_video_directory, exist_ok=True)
    os.makedirs(output_directory, exist_ok=True)

    # List subdirectories within the base directory
    s3 = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(s3_bucket_name)

    for obj in bucket.objects.filter(Prefix=s3_source_directory):
        if obj.key != s3_source_directory:
            logger.info(f'Download video {obj.key}')
            download_from_s3(s3_bucket_name, obj.key, os.path.join(source_video_directory))

    file_list = [ os.path.join(source_video_directory, obj.key.split("/")[-1]) for obj in bucket.objects.filter(Prefix=s3_source_directory)]
    f = open(os.path.join(source_video_directory, "file_list.txt"), "w")
    for file in file_list:
        f.write(f'file \'{file}\'\n')
    f.close()

    # Change directory to access the source files
    os.chdir(source_video_directory)

    logger.info('Encode the video')
    # Use FFmpeg to create a video from images in the directory
    subprocess.run(['/opt/ffmpeg/ffmpeg', '-f', 'concat', '-safe', '0', '-i', 'file_list.txt', '-codec', 'copy', os.path.join(output_directory, output_file_name)], check=True)

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

# if __name__ == "__main__":
#     event = {
#         "s3_parameters": {
#             "bucket_directory_year": "2023",
#             "bucket_directory_month": "12",
#             "bucket_directory_day": "01",
#         }
#     }
#     lambda_handler(event, "")
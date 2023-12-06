import subprocess
import boto3
import os
import tempfile

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
    s3_base_directory = 'images/2023/12/01/'  # Specify the base directory path within the bucket
    source_directory = '/tmp/source/'
    destination_directory = '/tmp/output.mp4'
    output_file_name = 'output.mp4'  # Name for the output video file

    # Ensure the local directories exist
    os.makedirs(source_directory, exist_ok=True)

    # List subdirectories within the base directory
    s3 = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(s3_bucket_name)

    for obj in bucket.objects.filter(Prefix=s3_base_directory):
        if obj.key != s3_base_directory:
            subdirectory = obj.key[len(s3_base_directory):].split('/')[0]
            download_from_s3(s3_bucket_name, obj.key, os.path.join(source_directory, subdirectory))

    # Change directory to access the source files
    os.chdir(source_directory)

    # Use FFmpeg to create a video from images in the directory
    subprocess.run(['ffmpeg', '-framerate', '30', '-pattern_type', 'glob', '-i', '*.jpg', '-c:v', 'libx265', '-pix_fmt', 'yuv420p', destination_directory], check=True)

    # Upload the resulting video to S3
    upload_to_s3(s3_bucket_name, destination_directory, 'videos', output_file_name)

    return {
        'statusCode': 200,
        'body': 'Video transcoding complete.'
    }

if __name__ == "__main__":
    lambda_handler("", "")

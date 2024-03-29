import subprocess
import boto3
import botocore
import boto3.s3.transfer as s3transfer
import os
import logging
import shutil

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.handlers = []

log_formatter = logging.Formatter('%(levelname)s %(asctime)s %(message)s')

log_stream = logging.StreamHandler()
log_stream.setLevel(logging.INFO)
log_stream.setFormatter(log_formatter)
logger.addHandler(log_stream)


def download_from_s3_transfer(bucket_name, s3_directory, local_directory, file_list, workers=30):
    botocore_config = botocore.config.Config(max_pool_connections=workers)
    s3client = boto3.Session().client('s3', config=botocore_config)
    transfer_config = s3transfer.TransferConfig(
        use_threads=True,
        max_concurrency=workers,
    )
    s3t = s3transfer.create_transfer_manager(s3client, transfer_config)
    for file in file_list:
        # dst = os.path.join(s3_directory, os.path.basename(file))
        logger.info(f'Adding transfer of {os.path.join(s3_directory, file)}')

        s3t.download(
            bucket_name, os.path.join(s3_directory, file), os.path.join(local_directory, file),
            # subscribers=[
            #     s3transfer.ProgressCallbackInvoker(progress_func),
            # ],
        )
    s3t.shutdown()  # wait for all the upload tasks to finish


def upload_to_s3(bucket_name, local_file_path, s3_directory, s3_file_name, content_type='video/mp4'):
    s3_client = boto3.client('s3')
    logger.info(f'Uploading the video {local_file_path} to {s3_directory}/{s3_file_name}')
    s3_client.upload_file(
        local_file_path,
        bucket_name,
        f'{s3_directory}/{s3_file_name}',
        ExtraArgs={'ContentType': content_type}
    )


def lambda_handler(event, context):
    s3_parameters = event['s3_parameters']

    logger.info(f'Event data: {event}')

    # Replace with your bucket name and source/destination directories
    if 'bucket_name' in s3_parameters.keys():
        s3_bucket_name = s3_parameters['bucket_name']
    else:
        s3_bucket_name = 'webcampi'

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
    output_file_name = f'{s3_date_year}_{s3_date_month}_{s3_date_day}_{s3_date_hour}.mp4'

    # Delete the content of the directories
    # (it looks like the block device is being re-used and there are leftover files from previous run)
    shutil.rmtree(image_directory, ignore_errors=True)
    shutil.rmtree(output_directory, ignore_errors=True)

    # Ensure the local directories exist
    os.makedirs(image_directory, exist_ok=True)
    os.makedirs(output_directory, exist_ok=True)

    # List subdirectories within the base directory
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(s3_bucket_name)

    # for obj in bucket.objects.filter(Prefix=s3_source_directory):
    #     if obj.key != s3_source_directory:
    #         download_from_s3(s3_bucket_name, obj.key, os.path.join(image_directory))

    file_list = []
    for obj in bucket.objects.filter(Prefix=s3_source_directory):
        if obj.key.endswith('.jpg'):
            file_list.append(obj.key.split('/')[-1])

    download_from_s3_transfer(s3_bucket_name, s3_source_directory, os.path.join(image_directory), file_list)

    # Change directory to access the source files
    os.chdir(image_directory)

    logger.info('Encode the video')
    # Use FFmpeg to create a video from images in the directory
    subprocess.run(
        [
            '/opt/ffmpeg/ffmpeg',
            '-y',
            '-framerate',
            '30',
            '-pattern_type',
            'glob',
            '-i',
            '*.jpg',
            '-c:v',
            'libx265',
            '-vtag',
            'hvc1',
            '-pix_fmt',
            'yuv420p',
            os.path.join(output_directory, output_file_name)
        ],
        check=True
    )

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

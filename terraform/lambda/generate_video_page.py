import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.handlers = []

log_formatter = logging.Formatter('%(levelname)s %(asctime)s %(message)s')

log_stream = logging.StreamHandler()
log_stream.setLevel(logging.INFO)
log_stream.setFormatter(log_formatter)
logger.addHandler(log_stream)

def upload_to_s3(bucket_name, local_file_path, s3_directory, s3_file_name, content_type=''):
    s3_client = boto3.client('s3')

    s3_client.upload_file(
        local_file_path,
        bucket_name,
        f'{s3_directory}/{s3_file_name}',
        ExtraArgs={'ContentType': content_type}
    )

def lambda_handler(event, context):
    s3_parameters = event['s3_parameters']

    # Replace with your bucket name and source/destination directories
    if 'bucket_name' in s3_parameters.keys():
        s3_bucket_name = s3_parameters['bucket_name']
    else:
        s3_bucket_name ='webcampi'

    if 'video_directory' in s3_parameters.keys():
        video_directory = s3_parameters['video_directory']
    else:
        video_directory ='video'

    # List subdirectories within the base directory
    s3 = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(s3_bucket_name)

    video_list = []

    for obj in bucket.objects.filter(Prefix=video_directory+'/'):
        if obj.key != video_directory:
            file_name = obj.key.split('/')[-1]
            if file_name != '':
                logger.info(f'Add video {file_name} to list')
                video_list.append(file_name)

    logger.info('Generate the HTML')

    nl = '\n'

    html_page_beginning = """<html>
<head>
<title>Video list</title>
</head>
<body>
<p style="font-size:20px">
    """

    html_page_end = """</p></body>
</html>
    """


    output_directory = '/tmp/output'
    output_file_name = f'index.html'  # Name for the output video file

    f = open(f'{output_directory}/{output_file_name}', "w")
    f.write(html_page_beginning)

    f.write('<ul>')
    for video in video_list:
        f.write(f'<li><a href={video}>{video}</a></li>{nl}')
    f.write('</ul>')

    f.write(html_page_end)
    f.close()

    # Upload the resulting video to S3
    upload_to_s3(
        bucket_name=s3_bucket_name,
        local_file_path=os.path.join(output_directory, output_file_name),
        s3_directory=video_directory,
        s3_file_name=output_file_name,
        content_type='text/html'
    )

    return {
        'statusCode': 200,
        'body': 'Video list upload complete.'
    }

if __name__ == "__main__":
    event = {
        "s3_parameters": {
            "s3_bucket_name": "webcampi",
            "video_directory": "video"
        }
    }
    lambda_handler(event, "")

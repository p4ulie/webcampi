#!/usr/bin/python3
# -*- coding: utf-8 -*-

# Copyright (c) Rau Systemberatung GmbH (rausys.de)
# MIT License
# credits: https://pyimagesearch.com/start-here/

import argparse
import os
from datetime import datetime, timedelta
from dataclasses import dataclass, field

import imutils
import time
import cv2
import boto3

from settings import STREAM_URL, CAMERA_WIDTH, DEBUG, \
    OUTPUT_INTERVAL, OUTPUT_PATH, OUTPUT_STATIC, \
    BUCKET_NAME

argparser = argparse.ArgumentParser()
argparser.add_argument(
    '-s', '--stream',
    help='Stream URL (RTSP) to get video feed from',
    nargs='?', type=str,
    default=STREAM_URL
)
argparser.add_argument(
    '-w', '--window',
    help='Show relevant feeds as X11 window',
    action='store_true')
argparser.add_argument(
    '--debug',
    help='Output more information',
    action='store_true'
)
args = argparser.parse_args()
DEBUG = args.debug or DEBUG

# Helper variables:
# last static saving tracking
last_static = datetime.now()

def get_stream():
    if not args.stream:
        print('Stream URI for RTSP server not specified! Exiting')
        exit(1)
    return cv2.VideoCapture(args.stream)

def upload_image(file_name, bucket, remote_file_name):
    s3.meta.client.upload_file( file_name, bucket, remote_file_name)

def update_latest_image(bucket, remote_file_name):
    copy_source = {
        'Bucket': bucket,
        'Key': remote_file_name
    }
    s3.meta.client.copy(copy_source, bucket, 'latest.jpg')

if __name__ == '__main__':
    print('Initializing stream...')
    vs = get_stream()

    s3 = boto3.resource('s3')

    while True:
        # grab the current frame and initialize the occupied/unoccupied
        retrieved, full_frame = vs.read()
        if not retrieved:
            print('Error retrieving image from stream; reinitializing')
            vs = get_stream()
            continue

        # save image to output static image every two seconds
        if OUTPUT_STATIC and last_static < datetime.now() - timedelta(seconds=OUTPUT_INTERVAL):
            last_static = datetime.now()
            last_static_string = last_static.strftime("%Y-%m-%d_%H-%M-%S")
            last_static_string_date = last_static.strftime("%Y-%m-%d")
            last_static_string_year = last_static.strftime("%Y")
            last_static_string_month = last_static.strftime("%m")
            last_static_string_day = last_static.strftime("%d")
            last_static_string_hour = last_static.strftime("%H")

            remote_file_name = last_static_string_year+"/"+last_static_string_month+"/"+last_static_string_day+"/"+last_static_string_hour+"/"+last_static_string+'.jpg'

            smol_frame = imutils.resize(full_frame, width=CAMERA_WIDTH)
            #cv2.imwrite(os.path.join(OUTPUT_PATH, last_static_string+'.jpg'), full_frame)
            cv2.imwrite(os.path.join(OUTPUT_PATH, last_static_string+'.jpg'), smol_frame)

            upload_image(
                os.path.join(OUTPUT_PATH, last_static_string+'.jpg'),
                BUCKET_NAME,
                remote_file_name
            )
            update_latest_image(
                BUCKET_NAME,
                remote_file_name
            )

        # show the frame and record if the user presses a key
        if args.window:
            cv2.imshow("Security Feed", full_frame)

        key = cv2.waitKey(1) & 0xFF
        # if the `q` key is pressed, break from the lop
        if key == ord("q"):
            break

    # cleanup the camera and close any open windows
    vs.release()  # vs.stop()
    cv2.destroyAllWindows()

#!/usr/bin/env bash

export BUCKET_NAME="webcampi"
export AWS_ACCESS_KEY_ID=<aws_access_key>
export AWS_SECRET_ACCESS_KEY=<aws_secret_key>

export CAMERA_URL="rtsp://<username>:<password>@192.168.200.102:554/stream1" # alternately smaller stream2, which supports multiple simultaneous connections
export CAMERA_OUTPUT="True"
export CAMERA_OUTPUT_INTERVAL=10
export CAMERA_OUTPUT_PATH="/home/paulie/images"
export CAMERA_WIDTH=1280

/usr/bin/python3 camera.py

exit 0

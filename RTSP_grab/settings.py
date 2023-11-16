#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
from distutils.util import strtobool

BUCKET_NAME = os.environ['BUCKET_NAME']

STREAM_URL = os.environ['CAMERA_URL']
CAMERA_WIDTH = int(os.environ.get('CAMERA_WIDTH', 1080))

# Periodically save static image of stream
OUTPUT_STATIC: bool = strtobool(os.environ.get('CAMERA_OUTPUT', 'True'))
OUTPUT_PATH: str = os.environ.get('CAMERA_OUTPUT_PATH', '.')
OUTPUT_INTERVAL: int = int(os.environ.get('CAMERA_OUTPUT_INTERVAL', 1))

DEBUG: bool = strtobool(os.environ.get('CAMERA_DEBUG', 'False'))


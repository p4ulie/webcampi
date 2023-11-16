#!/usr/bin/env bash

PID=$$

function cleanup {
  rm -f /var/run/user/${UID}/s3_sync.pid
}
trap cleanup SIGINT
trap cleanup SIGSTOP
trap cleanup SIGTERM

export AWS_ACCESS_KEY_ID=<aws_access_key>
export AWS_SECRET_ACCESS_KEY=<aws_secret_key>

DIR="/home/paulie/images"
SUB_DIR="thumb"
PATTERN="latest_thumb_"

S3_BUCKET="webcampi"

if [[ -f /var/run/user/${UID}/s3_sync.pid ]]; then
  echo "Another instance of s3_sync.sh already running, PID: $(cat /var/run/user/${UID}/s3_sync.pid)"
  exit 0
fi

echo "${PID}" > /var/run/user/${UID}/s3_sync.pid

LATEST_FILE=$(ls -rtl ${DIR}/${SUB_DIR}/${PATTERN}*.jpg | tail -1 | cut -d  " " -f 9)

/usr/local/bin/aws s3 sync "${DIR}/${SUB_DIR}" s3://${S3_BUCKET} --exclude "*" --include "${PATTERN}*.jpg"

RESULT=$?

if [[ "${RESULT}" == "0" ]]; then
  /usr/bin/find "${DIR}/${SUB_DIR}" -name "${PATTERN}*.jpg" -mmin +1440 -delete
  /usr/bin/find "${DIR}/full" -name "latest_full*.jpg" -mmin +1440 -delete
fi

# sync backlog images
/usr/local/bin/aws s3 sync "${DIR}/backlog" s3://${S3_BUCKET} --exclude "*" --include "*.jpg"

cleanup

exit 0

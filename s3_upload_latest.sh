#!/usr/bin/env bash

DELAY=1
DIR="/home/paulie/images"
SUB_DIR="thumb"
PATTERN="latest_thumb_"

S3_BUCKET="webcampi"

PID=$$

function cleanup {
  rm -f /var/run/user/${UID}/s3_upload_latest.pid
}
trap cleanup SIGINT
trap cleanup SIGSTOP
trap cleanup SIGTERM

export AWS_ACCESS_KEY_ID=<aws_access_key>
export AWS_SECRET_ACCESS_KEY=<aws_secret_key>

if [[ -f /var/run/user/${UID}/s3_upload_latest.pid ]]; then
  echo "Another instance of s3_upload_latest.sh already running, PID: $(cat /var/run/user/${UID}/s3_upload_latest.pid)"
  exit 0
fi

echo "${PID}" > /var/run/user/${UID}/s3_upload_latest.pid

PREVIOUS_LATEST_FILE=""

while :
do
  LATEST_FILE=$(ls -rt ${DIR}/${SUB_DIR}/${PATTERN}*.jpg | tail -1)

  if [[ "${PREVIOUS_LATEST_FILE}" != "${LATEST_FILE}" ]]; then

    cp "${LATEST_FILE}" "${DIR}/latest.jpg"

    echo "Uploading file ${LATEST_FILE}..."
    /usr/local/bin/aws s3 cp "${DIR}/latest.jpg" s3://${S3_BUCKET} --metadata-directive REPLACE --cache-control max-age=0,no-cache,no-store,must-revalidate

    PREVIOUS_LATEST_FILE="${LATEST_FILE}"
  else
    echo "No newer file, skipping upload."
  fi

  sleep "${DELAY}"
done

cleanup

exit 0

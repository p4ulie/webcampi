#!/usr/bin/env bash

YEAR="2023"
MONTH="09"

filename="payload.json"

for day in $(seq  -f "%02g" 10 30)
do
    echo "{\"s3_parameters\": { \"bucket_directory_year\": \"${YEAR}\", \"bucket_directory_month\": \"${MONTH}\", \"bucket_directory_day\": \"${day}\"}}" | jq > ${filename}
    cat "${filename}"
    time aws --profile terraform lambda invoke --invocation-type RequestResponse --function-name convert_day --payload fileb://payload.json response.json --cli-read-timeout 0 --cli-connect-timeout 0
done

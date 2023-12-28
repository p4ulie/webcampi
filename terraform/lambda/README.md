To test the lmabda, invoke using this command: 
```shell
aws --profile terraform lambda invoke --invocation-type RequestResponse --function-name convert_day --payload fileb://payload.json response.json --cli-read-timeout 0 --cli-connect-timeout 0 
```

with payload.json:
```json
{
  "s3_parameters": {
    "bucket_directory_year": "2023",
    "bucket_directory_month": "12",
    "bucket_directory_day": "01"
  }
}
```

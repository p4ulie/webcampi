```shell
sudo apt  install awscli
aws configure
aws s3 ls
mkdir images
sudo apt install ffmpeg x265
```

Sync directories

```shell
mkdir -p "${HOME}/images/2023/11"
cd "${HOME}/images/2023/11"
for day in {26..29}; do aws s3 sync s3://webcampi/2023/11/${day} ${day}; done

```

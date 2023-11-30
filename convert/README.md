# Converting daily batch of images to video

## Intial setup of VM

```shell
sudo apt install awscli
aws configure
aws s3 ls
mkdir images
sudo apt install ffmpeg x265
```

## Sync directories

```shell
cd
mkdir -p "${HOME}/images/2023/11"
cd "${HOME}/images/2023/11"
for day in {26..29}; do aws s3 sync s3://webcampi/2023/11/${day} ${day}; done

```

## Run convert script

```shell
cd
time bash convert.sh
```

## Upload videos

```shell
aws s3 sync --exclude '*' --include '*.mp4' . s3://webcampi/video
```

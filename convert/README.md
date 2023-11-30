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

## Download and encoding performance

(about 5.2G per day, about 8153 files, 400kB-1MB of file size, 2304x1296)

### VT instance

### vt1.3xlarge instance

```shell
time aws s3 sync s3://webcampi/2023/11/29 images/2023/11/29

...
...
...

real    1m32.695s
user    0m39.036s
sys     0m13.781s
```

```shell
time ffmpeg -r 30 -pattern_type glob -i "images/2023/11/29/*/*.jpg" -c:v libx265 -pix_fmt yuv420p 2023-11-29.mp4

...
...
...
encoded 8153 frames in 447.31s (18.23 fps), 5587.99 kb/s, Avg QP:33.33

real    7m27.432s
user    70m40.063s
sys     0m13.900s

```

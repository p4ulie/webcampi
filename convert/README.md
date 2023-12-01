# Converting daily batch of images to video

## Intial setup of VM

```shell
sudo apt install -y awscli  ffmpeg x265
aws configure
aws s3 ls
mkdir images
```

## Sync directories

```shell
mkdir -p "${HOME}/images/2023/11"
for day in {26..29}; do aws s3 sync s3://webcampi/2023/11/${day} "${HOME}/images/2023/11/${day}"; done
```

## Run convert script

```shell
cd
time bash convert.sh
```

## Upload videos

```shell
aws s3 sync --exclude '*' --include '*.mp4' "${HOME}" s3://webcampi/video
```

## Download and encoding performance

(about 5.2G per day, about 8153 files, 400kB-1MB of file size, 2304x1296)

> Need to check if CPU only was used

### vt1.3xlarge instance

```shell
time aws s3 sync s3://webcampi/2023/11/29 images/2023/11/29

real    1m32.695s
user    0m39.036s
sys     0m13.781s
```

```shell
time ffmpeg -r 30 -pattern_type glob -i "images/2023/11/29/*/*.jpg" -c:v libx265 -pix_fmt yuv420p 2023-11-29.mp4

encoded 8153 frames in 447.31s (18.23 fps), 5587.99 kb/s, Avg QP:33.33

real    7m27.432s
user    70m40.063s
sys     0m13.900s

```

### t3.xlarge instance

```
Model name:                         Intel(R) Xeon(R) Platinum 8259CL CPU @ 2.50GHz
CPU family:                         6
Model:                              85
Thread(s) per core:                 2
Core(s) per socket:                 2
Socket(s):                          1
Stepping:                           7
BogoMIPS:                           4999.99
```

```shell
time aws s3 sync s3://webcampi/2023/11/30 images/2023/11/30

real    1m56.583s
user    1m9.559s
sys     0m26.152s
```

```shell
time ffmpeg -r 30 -pattern_type glob -i "images/2023/11/30/*/*.jpg" -c:v libx265 -pix_fmt yuv420p 2023-11-30.mp4

encoded 8095 frames in 1616.80s (5.01 fps), 7375.54 kb/s, Avg QP:33.36

real    26m56.959s
user    101m51.001s
sys     0m8.509s
```

### Desktop computer 

```
Model name:                         AMD Ryzen 7 3700X 8-Core Processor
CPU family:                         23
Model:                              113
Thread(s) per core:                 2
Core(s) per socket:                 8
Socket(s):                          1
Stepping:                           0
Frequency boost:                    enabled
CPU max MHz:                        4426,1709
CPU min MHz:                        2200,0000
BogoMIPS:                           7199.72

```

1 hour of video converted only, instead of 24 hours

```shell
encoded 311 frames in 21.17s (14.69 fps), 19708.29 kb/s, Avg QP:34.41
```

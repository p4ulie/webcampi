# Converting daily batch of images to video

## Intial setup of VM

```shell
sudo apt install -y ffmpeg x265 git unzip python
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
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

### vt1.3xlarge instance

```shell
time aws s3 sync s3://webcampi/2023/11/29 images/2023/11/29

real    1m32.695s
user    0m39.036s
sys     0m13.781s
```

#### SW enconding using standard build of ffmpeg 

```shell
time ffmpeg -r 30 -pattern_type glob -i "images/2023/11/29/*/*.jpg" -c:v libx265 -pix_fmt yuv420p 2023-11-29.mp4

encoded 8153 frames in 447.31s (18.23 fps), 5587.99 kb/s, Avg QP:33.33

real    7m27.432s
user    70m40.063s
sys     0m13.900s
```

#### HW enconding using AMD-Xilinx Alveo U30 media accelerator

https://www.hackster.io/bhashimi/introduction-to-alveo-u30-video-transcoding-000ea1
https://xilinx.github.io/video-sdk/v1.5/getting_started_on_prem.html
https://xilinx.github.io/video-sdk/v1.5/index.html

```shell
time ffmpeg -r 30 -pattern_type glob -i "images/2023/11/29/*/*.jpg" -c:v mpsoc_vcu_hevc -b:v 17000K 2023-11-29.mp4

frame= 8153 fps= 46 q=-0.0 Lsize=  563992kB time=00:04:31.70 bitrate=17004.9kbits/s speed=1.55x
video:563909kB audio:0kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.014738%

real    3m1.237s
user    2m38.043s
sys     0m3.624s
```

#### Specify number of cores to use (2 available)

```shell
time ffmpeg -r 30 -pattern_type glob -i "images/2023/11/29/*/*.jpg" -cores 2 -c:v mpsoc_vcu_hevc -b:v 17000K 2023-11-29_hw.mp4

rame= 8153 fps= 47 q=-0.0 Lsize=  564003kB time=00:04:31.70 bitrate=17005.2kbits/s speed=1.56x
video:563920kB audio:0kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.014736%

real    2m56.852s
user    2m37.109s
sys     0m3.587s

```

#### Test transcode mp4 -> mp4 (JPG decoding seems to be software only), 1 core

```shell
time ffmpeg -r 30 -c:v mpsoc_vcu_hevc  -i 2023-11-29.mp4 -cores 1 -c:v mpsoc_vcu_hevc -b:v 17000K 2023-11-29_hw.mp4

frame= 8153 fps= 67 q=-0.0 Lsize=  563943kB time=00:04:31.70 bitrate=17003.4kbits/s speed=2.22x
video:563860kB audio:0kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.014747%

real    2m58.163s
user    0m2.243s
sys     0m2.495s
```

#### Test transcode mp4 -> mp4 (JPG decoding seems to be software only), 2 cores

```shell
time ffmpeg -r 30 -c:v mpsoc_vcu_hevc  -i 2023-11-29.mp4 -cores 1 -c:v mpsoc_vcu_hevc -b:v 17000K 2023-11-29_hw.mp4

frame= 8153 fps=124 q=-0.0 Lsize=  563977kB time=00:04:31.70 bitrate=17004.4kbits/s speed=4.15x
video:563894kB audio:0kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.014717%

real    1m7.780s
user    0m2.249s
sys     0m2.352s
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

> 1 hour of video converted only, instead of 24 hours

#### SW enconding using standard build of ffmpeg

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

```shell
time ffmpeg -r 30 -pattern_type glob -i "images/2023/11/30/*/*.jpg" -c:v libx265 -pix_fmt yuv420p 2023-11-30.mp4

encoded 311 frames in 19.84s (15.67 fps), 19708.29 kb/s, Avg QP:34.41

260,29s user
1,09s system
723% cpu
36,130 total
```

#### AMD Radeon 5700XT acceleration

```shell
time ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi -r 30 -pattern_type glob -i "images/2023/11/30/*/*.jpg" -c:v hevc_vaapi -b:v 19M -pix_fmt yuv420p 2023-11-30_hw.mp4

frame=  311 fps= 58 q=-0.0 Lsize=  136068kB time=00:00:10.33 bitrate=107870.6kbits/s speed=1.92x    

1,91s user
0,40s system
42% cpu
5,488 total
```

15.67fps vs 58 fps = about 4x faste GPU enconding

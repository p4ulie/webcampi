#!usr/bin/env bash

DIR=${HOME}/images
YEAR=2023
MONTH=11

for day in {11..25};
do
  for hour in {00..23};
  do
#    ls ${DIR}/${YEAR}/${MONTH}/${day}/*/*.jpg
    ffmpeg -r 30 -pattern_type glob -i "${DIR}/${YEAR}/${MONTH}/${day}/*/*.jpg" -c:v libx265 -pix_fmt yuv420p ${YEAR}-${MONTH}-${day}.mp4
  done
done

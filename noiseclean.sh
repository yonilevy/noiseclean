#!/usr/bin/env bash

set -e

usage ()
{
    echo 'Usage : noiseclean.sh <input video file> <output video file>'
    exit
}

# Tests for requirements
ffmpeg -version >/dev/null || { echo >&2 "We require 'ffmpeg' but it's not installed. Install it by 'sudo apt-get install ffmpeg' Aborting."; exit 1; }
sox --version >/dev/null || { echo >&2 "We require 'sox' but it's not installed. Install it by 'sudo apt-get install sox' Aborting."; exit 1; }

if [ "$#" -ne 2 ]
then
  usage
fi

if [ ! -e "$1" ]
then
    echo "File not found: '$1'"
    exit
fi

if [ -e "$2" ]
then
    read -p "File '$2' already exists, overwrite? [y/N]: " yn
    case $yn in
        [Yy]* ) break;;
        * ) exit;;
    esac
fi

inBasename=$(basename "$1")
inExt="${inBasename##*.}"

isVideoStr=`ffprobe -v warning -show_streams "$1" | grep codec_type=video`
if [[ ! -z $isVideoStr ]]
then
    isVideo=1
    echo "Detected '$inBasename' as a video file"
else
    isVideo=0
    echo "Detected '$inBasename' as an audio file"
fi

read -p "Sample noise start time [00:00:00]: " sampleStart
if [[ -z $sampleStart ]] ; then sampleStart="00:00:00"; fi
read -p "Sample noise end time [00:00:00.500]: " sampleEnd
if [[ -z $sampleEnd ]] ; then sampleEnd="00:00:00.500"; fi
read -p "Noise reduction amount [0.21]: " sensitivity
if [[ -z $sensitivity ]] ; then sensitivity="0.21"; fi


tmpVidFile="/tmp/noiseclean_tmpvid.$inExt"
tmpAudFile="/tmp/noiseclean_tmpaud.wav"
noiseAudFile="/tmp/noiseclean_noiseaud.wav"
noiseProfFile="/tmp/noiseclean_noise.prof"
tmpAudCleanFile="/tmp/noiseclean_tmpaud-clean.wav"

echo "Cleaning noise on '$1'..."

if [ $isVideo -eq "1" ]; then
    echo "Demux audio and video"
    ffmpeg -v warning -y -i "$1" -qscale:v 0 -vcodec copy -an "$tmpVidFile"
    ffmpeg -v warning -y -i "$1" -qscale:a 0 "$tmpAudFile"
else
    cp "$1" "$tmpAudFile"
fi
echo "Extract audio noise sample"
ffmpeg -v warning -y -i "$1" -vn -ss "$sampleStart" -t "$sampleEnd" "$noiseAudFile"
echo "Create noise profile"
sox "$noiseAudFile" -n noiseprof "$noiseProfFile"
echo "Reduce noise throughout audio recording"
sox "$tmpAudFile" "$tmpAudCleanFile" noisered "$noiseProfFile" "$sensitivity"
if [ $isVideo -eq "1" ]; then
    echo "Mux cleaned audio and video"
    ffmpeg -v warning -y -i "$tmpAudCleanFile" -i "$tmpVidFile" -strict -2 -vcodec copy -qscale:v 0 -qscale:a 0 "$2"
else
    cp "$tmpAudCleanFile" "$2"
fi

echo "Done"

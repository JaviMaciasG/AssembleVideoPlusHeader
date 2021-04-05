#!/bin/bash

# Variablese
HEADER_LENGTH_SECONDS=5


HEADER_FILE=$1
VIDEO_INPUT_FILE=$2
VIDEO_OUTPUT_FILE=$3

if [ "$HEADER_FILE" == "" ]
then
    echo "missing image to be used, should be argument 1"
    exit 1
fi

if [ "$VIDEO_INPUT_FILE" == "" ]
then
    echo "missing input video to be used, should be argument 2"
    exit 2
fi

if [ "$VIDEO_OUTPUT_FILE" == "" ]
then
    echo "missing output video to be used, should be argument 3"
    exit 2
fi


## Find out video details
VIDEO_RESOLUTION=`ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 $VIDEO_INPUT_FILE`
WIDTH=`echo $VIDEO_RESOLUTION | cut -f 1 -d "x"`
HEIGHT=`echo $VIDEO_RESOLUTION | cut -f 2 -d "x"`
echo "Detected video frame size: $VIDEO_RESOLUTION ($WIDTH x $HEIGHT)"
FRAME_RATE_Q=`ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate $VIDEO_INPUT_FILE`
FRAME_RATE_F=`echo $FRAME_RATE_Q | bc -l`
echo "Detected video frame rate: $FRAME_RATE_Q ($FRAME_RATE_F)"
NFRAMES_VIDEO=`ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 $VIDEO_INPUT_FILE`
let "NFRAMES_VIDEO=$NFRAMES_VIDEO-30"
echo "Detected video num frames: $NFRAMES_VIDEO+30 frames"

# Generate header video file
EXTENSION="${HEADER_FILE##*.}"
BASENAME=`basename $HEADER_FILE .$EXTENSION`
TMP_VIDEO=`mktemp`.mp4
TMP_AUDIO=`mktemp`.wav
HEADER_VIDEO=`mktemp`.mp4


echo "Generating header/footer video [$HEADER_VIDEO] from [$HEADER_FILE]"
(ffmpeg -y -r $FRAME_RATE_Q -loop 1 -i $1 -c:v libx264 -vf "fps=$FRAME_RATE_F,scale=$WIDTH:$HEIGHT" -pix_fmt yuv420p  -t $HEADER_LENGTH_SECONDS $TMP_VIDEO >& /dev/null) 
(($? > 0)) && echo "Error generating header/footer video from image file" && exit 1

echo "Generating audio for header/footer video [$TMP_AUDIO]"
(sox -n -r 16000 -c 1 $TMP_AUDIO trim 0.0 $HEADER_LENGTH_SECONDS)
(($? > 0)) && echo "Error generating audio silence file" && exit 1

echo "Generating merged audio and video for header/footer [$HEADER_VIDEO]"
(ffmpeg -y -i $TMP_VIDEO -i $TMP_AUDIO -c:v copy -c:a aac $HEADER_VIDEO >& /dev/null) 
(($? > 0)) && echo "Error merging header video and audio" && exit 1

# Find out number of frames
NFRAMES_HEADER=`ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 $HEADER_VIDEO`
let "NFRAMES_HEADER=$NFRAMES_HEADER-30"

echo "Detected header num frames: $NFRAMES_HEADER+30 frames"
##exit 1

# Generate fade-in fade-out files
TMP_VIDEO1=`mktemp`.mp4
TMP_VIDEO2=`mktemp`.mp4
echo "Fading in and out header file [$TMP_VIDEO1]"
bash go.fadeinout.sh $HEADER_VIDEO $TMP_VIDEO1
(($? > 0)) && echo "Error in call to go.fadeinout.sh for header file" && exit 1

echo "Fading in and out video input file [$TMP_VIDEO2]"
bash go.fadeinout.sh $VIDEO_INPUT_FILE $TMP_VIDEO2
(($? > 0)) && echo "Error in call to go.fadeinout.sh for video file" && exit 1


# Now concatenate
echo "Concatenating files to generate [$VIDEO_OUTPUT_FILE]"
ffmpeg -y -i $TMP_VIDEO1 -i $TMP_VIDEO2 -i $TMP_VIDEO1 -filter_complex "[0:v][0:a][1:v][1:a][2:v][2:a] concat=n=3:v=1:a=1[v][a]:unsafe=1" -map "[v]" -map "[a]" $VIDEO_OUTPUT_FILE >& /dev/null
(($? > 0)) && echo "Error when concatenating files" && exit 1




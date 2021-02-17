#!/bin/bash

# Audio + vidéo fade out at the end of mp4 files

# 2015-09-09 19:07:17.0 +0200 / Gilles Quenot

# length of the fade out
fade_duration=1 # seconds

if [[ ! $2 ]]; then
    cat<<EOF
Usage:
    ${0##*/} <input mp4> <output mp4>
EOF
    exit 1
fi

for x in bc awk ffprobe ffmpeg; do
    if ! type &>/dev/null $x; then
        echo >&2 "$x should be installed"
        ((err++))
    fi
done

((err > 0)) && exit 1

duration=$(ffprobe -select_streams v -show_streams "$1" 2>/dev/null |
    awk -F= '$1 == "duration"{print $2}')
final_cut=$(bc -l <<< "$duration - $fade_duration")
(ffmpeg -i "$1" \
    -filter:v "fade=in:0:30,fade=out:st=$final_cut:d=$fade_duration" \
    -af "afade=t=out:st=$final_cut:d=$fade_duration" \
    -c:v libx264 -crf 22 -preset veryfast -strict -2 "$2" >& /dev/null) || echo "Error fading file [$1] to [$2]"

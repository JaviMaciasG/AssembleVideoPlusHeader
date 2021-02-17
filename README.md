# AssembleVideoPlusHeader

The objective of these scripts is helping in the generation of a video
file by adding a given title image to the beginning and end of a video
file.

It is meant to be used when you have a "clean" video that does not
need to be edited, and you just want to add a title image 

It requires:

+ The title frame, in (hopefully) any image format
+ The main video, in (hopefully) any video format

The scripts will:

+ Generate a title video (default 5 seconds) by repeating the title frame

+ Modify the title and main videos with a fading-in and fading-out
  transition at the their beginning and end

+ Concatenate the title video + the main video + the title video 

# Usage

bash go.gen-header+video+footer.sh <title_image_file> <video_input_file> <video_output_file>

# Disclaimer

This is just a quick & dirty hack, with bash excerpts from many useful scripts. In particular the fade-in fade-out script is slightly adapted from one by Gilles Quenot.




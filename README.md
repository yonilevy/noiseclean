noiseclean
==========

A simple bash script to remove audio noise from audio and video files.

Usage example:
```
yoni@nicki:noiseclean → master ./noiseclean.sh intro.mp4 intro_cleaned.mp4
Detected 'intro.mp4' as a video file
Sample noise start time [00:00:00]:
Sample noise end time [00:00:00.500]:
Noise reduction amount [0.21]:
Cleaning noise on 'intro.mp4'...
Done
```

Based on: http://www.zoharbabin.com/how-to-do-noise-reduction-using-ffmpeg-and-sox/

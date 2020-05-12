# rule34_sound_autolooper


[**ffmpeg needs to be installed and in your PATH**](https://www.youtube.com/watch?v=qjtmgCb8NcE)
**Lua needs to be installed** 

![](https://i.imgur.com/Cnqzn2U.png)

![](https://i.imgur.com/ejAik0W.gif)

The issue with SFM/BLENDER/R34 videos is there is always a HQ 2 sec video (without sound) and a LQ 15 sec video with sound


This small script takes the audio from the LQ video, loops the HQ video the correct N of time (**WITHOUT ANY REENCODING**) and stick the audio from the LQ video to it.



You'll need Lua to run it, for windows you can get it [here](http://luabinaries.sourceforge.net/download.html)

For windows, just get the binaries, don't download the source code.


then run the following command : 


`lua.exe main.lua your_hq_video.mp4 your_lq_video.mp4`

**or just drag n drop the two video files on `r34_converter.bat`**

order of the videos files doesn't really matter, the LQ video duration should just be longer than the HQ one

your lua exe can vary, the whole process can fail because of the audio codec, it may be supported by webm and not by MP4 container


There may be issues with local names (you know, the ---->.\\<----my_local_video.mp4 thing) so i applied a dirty hotfix to it.



How to use : 

1) Get your fresh HQ video from patreon

2) Wait few hours/days

3) Get the LQ version with sound from R34

4) Use this tool to get a superior version with sound

5) Use MadVR+SVP

6) ???

7) Profit

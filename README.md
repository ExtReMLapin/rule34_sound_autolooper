# rule34_sound_autolooper


![](https://i.imgur.com/tEkDwhO.png)


The issue with SFM/BLENDER/R34 videos is there is always a HQ 2 sec video (without sound) and a LQ 15 sec video with sound


This small script takes the audio from the LQ video, loops the HQ video the correct N of time (**WITHOUT ANY REENCODING**) and stick the audio from the LQ video to it.



You'll need Lua to run it, for windows you can get it [here](http://luabinaries.sourceforge.net/download.html)

For windows, just get the binaries, don't download the source code.


then run the following command : 


`lua.exe main.lua your_hq_video.mp4 your_lq_video.mp4`

order of the video doesn't really matter, the LQ should just be longer than the HQ one

your lua exe can vary, and **it was only tested on windows with mp4 files**


There may be issues with local names (you know, the ---->.\\<----my_local_video.mp4 thing) so i applied a dirty hotfix to it.

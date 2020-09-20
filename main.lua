-- usage : lua main.lua hq_video_with_no_sound.mp4 lq_video_with_sound.mp4


function os.capture(cmd, raw)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()

	if raw then
		return s
	end

	s = string.gsub(s, '^%s+', '')
	s = string.gsub(s, '%s+$', '')
	s = string.gsub(s, '[\n\r]+', ' ')

	return s
end

function math.round( num, idp )
	local mult = 10 ^ ( idp or 0 )
	return math.floor( num * mult + 0.5 ) / mult
end

function string.startWith( String, Start )

	return string.sub( String, 1, string.len( Start ) ) == Start

end

local ffmpeg_cmd = "ffmpeg  -v error -y -hide_banner"
--local ffmpeg_cmd_no_error = "ffmpeg -y -hide_banner 2>&1"
local ffprobe_cmd_time = "ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1"
local ffprobe_cmd_resolution = "ffprobe -v error -hide_banner -show_entries stream=width,height -of default=noprint_wrappers=1:nokey=1"
local ffprobe_cmd_checkifaudio = "ffprobe -show_streams -select_streams a -loglevel error "
local tmp_output_audio = "tmp_output_audio.m4a"
local tmp_file_list = "tmp_concat_list.txt"

if (#arg ~= 2) then
	print("usage : r34HQ_converter.exe hq_video.mp4 lq_sound_video.mp4")
	return
end

-- lua script.lua video.mp4 sound.mp3/mp4
local input_videoHQ = arg[1]
local input_videoLQ_sound = arg[2]


if (string.startWith(input_videoHQ, ".\\")) then
	input_videoHQ = string.sub(input_videoHQ, 3, string.len(input_videoHQ))
end

if (string.startWith(input_videoLQ_sound, ".\\")) then
	input_videoLQ_sound = string.sub(input_videoLQ_sound, 3, string.len(input_videoLQ_sound))
end


local function getfile_duration(file_name)
	local commandRet = os.capture(string.format("%s \"%s\"", ffprobe_cmd_time, file_name))
	return tonumber(commandRet)
end

local function getvideo_quality(file_name)
	local commandRet = os.capture(string.format("%s \"%s\"", ffprobe_cmd_resolution, file_name))

	local nLinepos = string.find(commandRet, " ")
	local w = tonumber(commandRet:sub(1,nLinepos-1))
	local h = commandRet:sub(nLinepos + 1)
	return w * h
end

local function hasfile_audio(file_name)
	local commandRet = os.capture(string.format("%s \"%s\"", ffprobe_cmd_checkifaudio, file_name))
	print("commandRet size = " .. #commandRet)
	return #commandRet > 1
end



local video_sourceHQ = {
	path = input_videoHQ:gsub("\\", "/"),
	duration = getfile_duration(input_videoHQ),
	resolution = getvideo_quality(input_videoHQ),
	hasaudio = hasfile_audio(input_videoHQ)
}

local video_sourceLQ_sound = {
	path = input_videoLQ_sound:gsub("\\", "/"),
	duration = getfile_duration(input_videoLQ_sound),
	resolution = getvideo_quality(input_videoLQ_sound),
	hasaudio = hasfile_audio(input_videoLQ_sound)
}

print("HQ Video : ")
for k, v in pairs(video_sourceHQ) do print("\t" .. k .. " : " .. tostring(v)) end

print("-----------------------------------------------------------------------")

print("LQ Video with sound : ")
for k, v in pairs(video_sourceLQ_sound) do print("\t" .. k .. " : " .. tostring(v)) end

if video_sourceHQ.hasaudio == false then
	if video_sourceLQ_sound.hasaudio == false then print("No audio on both files.") end
	-- all good, good order
elseif (math.abs(video_sourceHQ.duration - video_sourceLQ_sound.duration) < 0.5) then -- more or less equal time
	if video_sourceHQ.resolution < video_sourceLQ_sound.resolution then
		print("The resolution of the LQ sound video shouldn't be greater than the duration of the HQ video, swapping them")
		local tmp = video_sourceHQ
		video_sourceHQ = video_sourceLQ_sound
		video_sourceLQ_sound = tmp
	end
elseif (video_sourceHQ.duration >  video_sourceLQ_sound.duration ) then
	-- if video declared as "hq" is clearly longer then "lq" supposed one, then there is clearly an issue and they need to be swaped
	print("The duration of the LQ sound video shouldn't be greater than the duration of the HQ video, swapping them")
	local tmp = video_sourceHQ
	video_sourceHQ = video_sourceLQ_sound
	video_sourceLQ_sound = tmp
end


local detected_required_loops = video_sourceLQ_sound.duration / video_sourceHQ.duration

local decimal_part = math.fmod(detected_required_loops, 1)

if (decimal_part > 0.15 and decimal_part < 0.85) then
	print("The number of required loops is " .. detected_required_loops)
	print("The decimal part is too significant and cannot be rounded up")
	--return
end

detected_required_loops = math.round(detected_required_loops)

----- extracting the audio from the LQ video -----

--ffmpeg -i sound.mp4 -vn -acodec copy output_audio.aac

-- os capture is used to not spam the console
print("Extracting audio from LQ video")
os.capture(string.format("%s -i \"%s\" -vn -acodec aac \"%s\"", ffmpeg_cmd, video_sourceLQ_sound.path, tmp_output_audio))


print("Creating concat list")
local file_content = string.format("file \'%s\'\n",video_sourceHQ.path)
file_content = string.rep(file_content,detected_required_loops )


local file = io.open(tmp_file_list, "w")
file:write(file_content)
file:close()

--ffmpeg -f concat -i .\tmp_concat_list.txt -i .\tmp_output_audio.aac -c copy output.mp4

print("Building video")
local filename = video_sourceHQ.path:match("[^/]*$")
local output_name = video_sourceHQ.path:gsub("[^/]*$", "HQ" .. filename, 1)

os.capture(string.format("%s -f concat -safe 0 -i \"%s\" -i \"%s\"  -c:v copy -map 0:v:0 -map 1:a:0  \"%s\"", ffmpeg_cmd, tmp_file_list, tmp_output_audio, output_name))
print("Removing temp files")
os.remove(tmp_output_audio)
os.remove(tmp_file_list)

print("Done !")
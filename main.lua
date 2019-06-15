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


local ffmpeg_cmd = "ffmpeg -y -hide_banner 2>&1"
local tmp_output_audio = "tmp_output_audio.aac"
local tmp_file_list = "tmp_concat_list.txt"
local input_videoHQ;
local input_videoLQ_sound;

-- lua script.lua video.mp4 sound.mp3/mp4
--input_videoHQ = arg[3]
--input_videoLQ_sound = arg[3]

input_videoHQ = "video.mp4"
input_videoLQ_sound = "sound.mp4"


local function getfile_duration(file_name)
	local command = os.capture(string.format("%s -i \"%s\"", ffmpeg_cmd, file_name))

	local durationPos = assert(string.find(command, "Duration:"))
	local durationEnd = assert(string.find(command, ",", durationPos))
	local duration = string.sub(command, durationPos + 10, durationEnd - 1)
	-- result is something like "00:00:01.27"

	-- fuck any video > 99 hours, now parsing the value
	local sec = tonumber(string.sub(duration, 7, string.len(duration)))
	sec = sec + tonumber(string.sub(duration, 4, 5)) * 60
	sec = sec + tonumber(string.sub(duration, 1, 2)) * 3600
	return sec
end


local video_sourceHQ = {path = input_videoHQ, duration = getfile_duration(input_videoHQ)}

local video_sourceLQ_sound = {path = input_videoLQ_sound, duration = getfile_duration(input_videoLQ_sound)}

print("HQ Video : ", video_sourceHQ.path, " Duration : ", video_sourceHQ.duration)
print("LQ Video with sound : ", video_sourceLQ_sound.path, " Duration : ", video_sourceLQ_sound.duration)

if ( video_sourceHQ.duration > video_sourceLQ_sound.duration) then
	print("The duration of the LQ sound video shouldn't be greater than the duration of the HQ video")
	return
end


local detected_required_loops = video_sourceLQ_sound.duration / video_sourceHQ.duration

local decimal_part = math.fmod(detected_required_loops, 1)

if (decimal_part > 0.15 and decimal_part < 0.85) then
	print("The number of required loops is " .. detected_required_loops)
	print("The decimal part is too significant and cannot be rounded up")
	return
end

detected_required_loops = math.round(detected_required_loops)

----- extracting the audio from the LQ video -----

--ffmpeg -i sound.mp4 -vn -acodec copy output_audio.aac

-- os capture is used to not spam the console
os.capture(string.format("%s -i \"%s\" -vn -acodec copy \"%s\"", ffmpeg_cmd, video_sourceLQ_sound.path, tmp_output_audio))



local file_content = string.format("file \'%s\'\n",video_sourceHQ.path)
file_content = string.rep(file_content,detected_required_loops )


local file = io.open(tmp_file_list, "w")
file:write(file_content)
file:close()

--ffmpeg -f concat -i .\tmp_concat_list.txt -i .\tmp_output_audio.aac -c copy output.mp4

os.capture(string.format("%s -f concat -i \"%s\" -i \"%s\" -c copy \"%s\"", ffmpeg_cmd, tmp_file_list, tmp_output_audio, "HQ_Plus_sound" .. video_sourceHQ.path))

os.remove(tmp_output_audio)
os.remove(tmp_file_list)

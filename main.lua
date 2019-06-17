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

local ffmpeg_cmd = "ffmpeg -y -hide_banner"
local ffmpeg_cmd_no_error = "ffmpeg -y -hide_banner 2>&1"
local tmp_output_audio = "tmp_output_audio.m4a"
local tmp_file_list = "tmp_concat_list.txt"

if (#arg ~= 2) then
	print("usage : lua main.lua hq_video.mp4 lq_sound_video.mp4")
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
	local command = os.capture(string.format("%s -i \"%s\"", ffmpeg_cmd_no_error, file_name))

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
	print("The duration of the LQ sound video shouldn't be greater than the duration of the HQ video, switching them")
	local tmp = video_sourceHQ
	video_sourceHQ = video_sourceLQ_sound
	video_sourceLQ_sound = tmp
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
local output_name = "HQ" .. video_sourceHQ.path
os.capture(string.format("%s -f concat -i \"%s\" -i \"%s\"  -c:v copy -map 0:v:0 -map 1:a:0  \"%s\"", ffmpeg_cmd, tmp_file_list, tmp_output_audio, output_name))

print("Removing temp files")
os.remove(tmp_output_audio)
os.remove(tmp_file_list)


print("Done !")

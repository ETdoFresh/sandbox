local Sound = {}

audio.reserveChannels(1)

-- Loaded files
local streams = {}
local sounds = {}

function Sound.remove(sound)
	if (streams[sound]) then audio.dispose(streams[sound]) end
	if (sounds[sound]) then audio.dispose(sounds[sound]) end
	streams[sound] = nil
	sounds[sound] = nil
end

function Sound.load(param)
	param = param or {}
	local file = param.file
	local baseDir = param.baseDir
	local isMusic = param.isMusic or false
	if (not(file)) then return false end
	Sound.remove(file)
	if (isMusic) then
		streams[file] = audio.loadStream(file, baseDir)
	else
		sounds[file] = audio.loadSound(file, baseDir)
	end
	return true
end

function Sound.play(param)
	param = param or {}
	local file = param.file
	if (not(file)) then return false end
	if (sounds[file]) then
		audio.play(sounds[file])
	elseif (streams[file]) then
		audio.play(streams[file], {channel = 1, loops = -1})
	else
		Sound.load(file)
		audio.play(sounds[file])
	end
end

return Sound
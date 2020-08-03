-- Pack DEPLS project to LS2 binary beatmap

local ls2 = require("ls2")
local JSON = require("JSON")
local arg = {...}
local input_dir = assert(arg[1], "Please specify input directory")
local output_dir = assert(arg[2], "Please specify output file")
local output_file = assert(io.open(output_dir, "wb"))

-- Add slash
if input_dir:sub(-1) ~= "/" and input_dir:sub(-1) ~= "\\" then
	input_dir = input_dir.."/"
end

local ext_img_list = {".png", ".jpg", ".jpeg", ".bmp"}
local function attempt_image(name)
	for i = 1, #ext_img_list do
		local f = io.open(input_dir..name..ext_img_list[i], "rb")
		if f then
			local r = f:read("*a")
			f:close()
			return r
		end
	end
end

-- Load .ls2_create.json file
local file = assert(io.open(input_dir..".ls2_create.json", "rb"), "Cannot find .ls2_create.json inside project")
local ls2_create = JSON:decode(file:read("*a"))

-- Load beatmap file
file:close()
file = assert(io.open(input_dir..(ls2_create.beatmap or "beatmap.json"), "rb"))
local beatmap = JSON:decode(file:read("*a"))

-- Load score and combo info
local score_info = ls2_create.scoreInfo
local combo_info = ls2_create.comboInfo

-- If no score info present, calculate our own
if not(score_info) then
	score_info = {nil, nil, nil, 0}
	
	for i = 1, #beatmap do
		local b = beatmap[i]
		
		score_info[4] = score_info[4] + (b.effect >= 11 and 370 or 739)
	end
	
	score_info[1] = math.floor(score_info[4] * 0.285521 + 0.5)
	score_info[2] = math.floor(score_info[4] * 0.71448 + 0.5)
	score_info[3] = math.floor(score_info[4] * 0.856563 + 0.5)
end

-- If no combo info present, calculate our own
if not(combo_info) then
	local s_combo = #beatmap
	combo_info = {}
	
	combo_info[1] = math.ceil(s_combo * 0.3)
	combo_info[2] = math.ceil(s_combo * 0.5)
	combo_info[3] = math.ceil(s_combo * 0.7)
	combo_info[4] = s_combo
end

-- Create LS2 writer
local ls2_hand = ls2.encoder.new(output_file, {
	name = ls2_create.name,
	star = ls2_create.star,
	random_star = ls2_create.star and ls2_create.random_star,
	score = score_info,
	combo = combo_info,
})

-- Set score tap base
if ls2_create.scoreTapBase then
	ls2_hand:set_score(ls2_create.scoreTapBase)
end

-- Set stamina
if ls2_create.staminaBase then
	ls2_hand:set_stamina(ls2_create.staminaBase)
end

-- Set note style
if ls2_create.noteStyle then
	ls2_hand:set_notes_style(ls2_create.noteStyle)
end

-- Add beatmap
ls2_hand:add_beatmap(beatmap)

-- If storyboard file exist, add it
do
	local f = io.open(input_dir.."storyboard.lua", "rb")
	if not(f) then
		f = io.open(input_dir.."storyboard.yaml", "rb")
	end

	if f then
		ls2_hand:add_storyboard(f:read("*a"))
		f:close()
	end
end

local function strip_crlf(s)
	return s:gsub("[\r|\n]", "")
end

-- Cover information
do
	local cover_info = io.open(input_dir.."cover.txt", "rb")
	
	if cover_info then
		local cover_img = io.open(input_dir.."cover.png", "rb")
		
		if cover_img then
			ls2_hand:add_cover_art({
				image = cover_img:read("*a"),
				title = strip_crlf(cover_info:read("*l")),
				arrangement = strip_crlf(cover_info:read("*l"))
			})
			
			cover_img:close()
		end
		
		cover_info:close()
	end
end

-- Unit data processing
do
	local unit_image = {}
	local unit_list = {}
	local has_units = false
	
	for i = 1, 9 do
		-- Attempt txt image
		local infile = io.open(input_dir.."unit_pos_"..i..".txt", "rb")
		
		if infile then
			local name = infile:read("*a")
			local destination = assert(io.open(input_dir..name, "rb"))
			
			unit_image[name] = destination:read("*a")
			unit_list[i] = name
			
			destination:close()
		else
			-- Attempt PNG image
			local name = "unit_pos_"..i..".png"
			
			if not(unit_image[name]) then
				local finput = io.open(input_dir..name, "rb")
				
				if finput then
					unit_image[name] = finput:read("*a")
					finput:close()
				end
			end
			
			unit_list[i] = name
		end
	end
	
	-- Add unit images
	local unit_image_index = {}
	local i = 1
	for n, v in pairs(unit_image) do
		unit_image_index[n] = i
		
		ls2_hand:add_unit_image({index = i, image = v})
		i = i + 1
		has_units = true
	end
	
	-- Add to unit info
	if has_units then
		for i = 1, 9 do
			local unit_info = unit_list[i]
			
			if unit_info then
				ls2_hand:add_unit_info({position = i, index = unit_image_index[unit_info]})
			end
		end
	end
end

-- Background image
do
	-- If background.txt exist and no star is present, use built-in background image
	local finput
	if not(ls2_create.star) then
		finput = io.open(input_dir.."background.txt", "rb")
		
		if finput then
			local bid = assert(tonumber(f:read("*a")), "Invalid background id")
			ls2_hand:set_background_id(bid)
		end
	end
	
	if not(finput) then
		-- Try background
		local bg0 = attempt_image("background")
		
		if bg0 then
			-- Has background
			ls2_hand:add_custom_background(bg0, 0)
			
			-- Try left-right background (16:9)
			local bga, bgb = attempt_image("background-1"), attempt_image("background-2")
			assert(not(not(bga)) == not(not(bgb)), "Background missing left/right part")
			
			if bga and bgb then
				ls2_hand:add_custom_background(bga, 1)
				ls2_hand:add_custom_background(bgb, 2)
			end
			
			-- Try top-bottom background (4:3)
			bga, bgb = attempt_image("background-3"), attempt_image("background-4")
			assert(not(not(bga)) == not(not(bgb)), "Background missing top/bottom part")
			
			if bga and bgb then
				ls2_hand:add_custom_background(bga, 3)
				ls2_hand:add_custom_background(bgb, 4)
			end
		end
	else
		finput:close()
	end
end

-- Song file and live clear audio
do
	local function get_audio_type(filename)
		local ext = assert(select(3, string.find(filename, "^.*()%.")), "Audio has no extension?")
		ext = filename:sub(ext + 1)
		
		if ext == "wav" then
			return "wave"
		elseif ext == "ogg" then
			return "vorbis"	-- but it also can be opus
		elseif ext == "mp3" then
			return "mp3"
		else
			return "custom:"..ext
		end
	end
	
	-- Song file
	if ls2_create.songFile then
		local fin = assert(io.open(input_dir..ls2_create.songFile, "rb"))
		ls2_hand:add_audio(get_audio_type(ls2_create.songFile), fin:read("*a"))
		fin:close()
	else
		-- Try all possible combination
		for n, v in ipairs {"songFile.wav", "songFile.ogg", "songFile.mp3"} do
			local fin = io.open(input_dir..v, "rb")
			
			if fin then
				ls2_hand:add_audio(get_audio_type(v), fin:read("*a"))
				fin:close()
				
				break
			end
		end
	end
	
	-- Live clear
	for n, v in ipairs {"live_clear.wav", "live_clear.ogg", "live_clear.mp3"} do
		local fin = io.open(input_dir..v, "rb")
		
		if fin then
			ls2_hand:add_live_clear_voice(get_audio_type(v), fin:read("*a"))
			fin:close()
			
			break
		end
	end
end

-- Additional data to be exported
if ls2_create.additionalData then
	for i = 1, #ls2_create.additionalData do
		local v = ls2_create.additionalData[i]
		local input = io.open(input_dir..v.path, "rb")
		
		if input then
			ls2_hand:add_storyboard_data(v.name, input:read("*a"))
			input:close()
		end
	end
end

-- Write
ls2_hand:write()
output_file:close()

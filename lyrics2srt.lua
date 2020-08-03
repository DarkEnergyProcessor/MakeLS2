-- lyrics.txt to storyboard.yaml
local arg = {...}
local input = assert(io.open(assert(arg[1], "please specify input"), "rb"))

local lineiter = input:lines()
local bpm, beat, ppqn = lineiter():match("^(%d+) (%d+) (%d+)")
assert(bpm and beat and ppqn, "invalid bpm, beat, and/or ppqn")

local function toSeconds(bar, bt, halv)
	bar = assert(tonumber(bar), "bar is not a number")
	bt = assert(tonumber(bt), "beat is not a number")
	halv = assert(tonumber(halv), "tick is not a number")
	return ((bar - 1) * beat + (bt - 1) + halv/ppqn) * 60 / bpm
end

local function toTimecode(sec)
	local ms = math.floor((sec * 1000) % 1000)
	local s = math.floor(sec % 60)
	local m = math.floor((sec / 60) % 60)
	local h = math.floor(sec / 3600)
	
	return string.format("%02d:%02d:%02d,%03d", h, m, s, ms)
end

local stringBuffer = {}

local function write(...)
	local a = {}
	for _, v in ipairs({...}) do
		a[#a + 1] = tostring(v)
	end
	stringBuffer[#stringBuffer + 1] = table.concat(a)
end

local function stripNewline(txt)
	while #txt > 0 do
		local a = txt:sub(-1)
		if a == "\r" or a == "\n" then
			txt = txt:sub(1, -2)
		else
			break
		end
	end

	return txt
end

local timings = {}

while true do
	local line = lineiter()
	if not(line) then break end
	local text1 = lineiter()
	if not(text1) then break end
	text1 = stripNewline(text1)
	local text2 = lineiter()
	if not(text2) then break end
	text2 = stripNewline(text2)

	-- Calculate
	local finditer = line:gmatch("(%d+):(%d+):(%d+)")
	local sbar, sbeat, shalv = finditer()
	assert(sbar and sbeat and shalv, "timing info not found")
	local ebar, ebeat, ehalv = finditer()
	local startTime = toSeconds(sbar, sbeat, shalv)
	
	-- Put in timings
	local t = {
		text1, text2,
		startTime, nil
	}
	
	if ebar and ebeat and ehalv then
		t[4] = toSeconds(ebar, ebeat, ehalv)
	end
	
	timings[#timings + 1] = t
end

for i, v in ipairs(timings) do
	if v[4] == nil then
		if i == #timings then
			-- assume ends after 10 seconds
			v[4] = v[1] + 10
		else
			v[4] = timings[i + 1][3] - 0.02
		end
	end
end

for i, v in ipairs(timings) do
	write(i)
	write(toTimecode(v[3]), " --> ", toTimecode(v[4]))
	if #v[1] > 0 then
		write(v[1])
	end
	if #v[2] > 0 then
		write(v[2])
	end
	write("")
end

io.write(table.concat(stringBuffer, "\n"))
input:close()

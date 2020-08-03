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

local stringBuffer = {
	"---",
	"init:",
	" - name: lyricsBlack",
	"   draw: text",
	"   x: 8",
	"   y: 592",
	"   red: 0",
	"   green: 0",
	"   blue: 0",
	"   font: __default:24",
	" - name: lyricsWhite",
	"   draw: text",
	"   x: 6",
	"   y: 590",
	"   font: __default:24",
	" - name: lyricsSmallBlack",
	"   draw: text",
	"   x: 7",
	"   y: 621",
	"   red: 0",
	"   green: 0",
	"   blue: 0",
	"   font: __default:16",
	" - name: lyricsSmallWhite",
	"   draw: text",
	"   x: 6",
	"   y: 620",
	"   font: __default:16",
	"",
	"storyboard:",
}

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

	-- Write
	write(" - time: ", startTime)
	write("   do:")
	-- Main text
	write("   - type: draw")
	write("     target: lyricsBlack")
	write("     alpha: 0")
	write("     text: '", text1, "'")
	write("   - type: set")
	write("     target: lyricsBlack")
	write("     alpha: tween 255 in 300 ms")
	write("   - type: draw")
	write("     target: lyricsWhite")
	write("     alpha: 0")
	write("     text: '", text1, "'")
	write("   - type: set")
	write("     target: lyricsWhite")
	write("     alpha: tween 255 in 300 ms")
	-- Smaller text
	write("   - type: draw")
	write("     target: lyricsSmallBlack")
	write("     alpha: 0")
	write("     text: '", text2, "'")
	write("   - type: set")
	write("     target: lyricsSmallBlack")
	write("     alpha: tween 255 in 300 ms")
	write("   - type: draw")
	write("     target: lyricsSmallWhite")
	write("     alpha: 0")
	write("     text: '", text2, "'")
	write("   - type: set")
	write("     target: lyricsSmallWhite")
	write("     alpha: tween 255 in 300 ms")

	if ebar and ebeat and ehalv then
		local endTime = toSeconds(ebar, ebeat, ehalv)
		write(" - time: ", endTime)
		write("   do:")
		-- Main text
		write("   - type: set")
		write("     target: lyricsBlack")
		write("     alpha: tween 0 in 300 ms")
		write("   - type: draw")
		write("     target: lyricsWhite")
		write("     alpha: tween 0 in 300 ms")
		-- Smaller text
		write("   - type: set")
		write("     target: lyricsSmallBlack")
		write("     alpha: tween 0 in 300 ms")
		write("   - type: set")
		write("     target: lyricsSmallWhite")
		write("     alpha: tween 0 in 300 ms")
		-- Undraw command
		write(" - time: ", endTime + 0.3)
		write("   do:")
		-- Main text
		write("   - type: undraw")
		write("     target: lyricsBlack")
		write("   - type: undraw")
		write("     target: lyricsWhite")
		-- Smaller text
		write("   - type: undraw")
		write("     target: lyricsSmallBlack")
		write("     alpha: tween 0 in 300 ms")
		write("   - type: undraw")
		write("     target: lyricsSmallWhite")
	end
end

print(table.concat(stringBuffer, "\n"))
input:close()

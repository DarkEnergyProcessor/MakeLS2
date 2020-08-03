local ls2 = require("ls2")
local arg = {...}

local input_name = assert(arg[1], "Please specify LS2 input file")
local input_file = assert(io.open(input_name, "rb"))
local output_dir = assert(arg[2], "Please specify output directory")

-- Append slash
do local x = output_dir:sub(-1)
if x ~= "/" or x ~= "\\" then x = x.."/" end end

-- Get basename
do while true do
	local a = input_name:find("[/|\\]")
	if not(a) then break end
	input_name = input_name:sub(a + 1)
end end

local ls2_hand = ls2.loadstream(input_file)

if ls2_hand.sections.UIMG then
	for i, uimg in ipairs(ls2_hand.sections.UIMG) do
		input_file:seek("set", uimg)
		
		local idx, img = ls2.section_processor.UIMG[1](input_file, ls2_hand.version_2)
		local f = assert(io.open(output_dir..input_name.."_unit_pos_"..idx..".png", "wb"))
		f:write(img)
		f:close()
	end
end

input_file:close()

-- button
-- checkbox
-- radiobutton
-- label
-- text input
-- list
local UI = {}

local font = { handle, w, h, scale = 1 }
local margin = 14
local windows = {}
local passes = {}
local colors =
{
	text = { 0.8, 0.8, 0.8 },
	window_bg = { 0.26, 0.26, 0.26 },
	window_border = { 0.4, 0.4, 0.4 },
	button_bg = { 0.14, 0.14, 0.14 },
	button_bg_hover = { 0.17, 0.17, 0.17 },
	button_bg_click = { 0.12, 0.12, 0.12 },
	button_border = { 0, 0, 0 }
}
local layout = { prev_x = 0, prev_y = 0, prev_w = 0, prev_h = 0, row_h = 0, total_w = 0, total_h = 0, same_line = false }

local function Hash( o )
	local b = require 'bit'
	local t = type(o)
	if t == 'string' then
		local len = #o
		local h = len
		local step = b.rshift(len, 5) + 1

		for i = len, step, -step do
			h = b.bxor(h, b.lshift(h, 5) + b.rshift(h, 2) + string.byte(o, i))
		end
		return h
	elseif t == 'number' then
		local h = math.floor(o)
		if h ~= o then
			h = b.bxor(o * 0xFFFFFFFF)
		end
		while o > 0xFFFFFFFF do
			o = o / 0xFFFFFFFF
			h = b.bxor(h, o)
		end
		return h
	elseif t == 'bool' then
		return t and 1 or 2
	elseif t == 'table' and o.hashcode then
		local n = o:hashcode()
		assert(math.floor(n) == n, "hashcode is not an integer")
		return n
	end

	return nil
end

local function Raycast( rayPos, rayDir, planePos, planeDir )
	local dot = rayDir:dot(planeDir)
	if math.abs(dot) < .001 then
		return nil
	else
		local distance = (planePos - rayPos):dot(planeDir) / dot
		if distance > 0 then
			return rayPos + rayDir * distance
		else
			return nil
		end
	end
end

local function DrawRay( pass )
	local position = vec3(lovr.headset.getPosition("hand/left"))
	local dir = vec3(quat(lovr.headset.getOrientation("hand/left")):direction())
	local tip = position + dir * 50
	pass:setColor(1, 0, 1)
	pass:sphere(tip, 0.3)
	pass:line(position, tip)
end

local function ResetLayout()
	layout = { prev_x = 0, prev_y = 0, prev_w = 0, prev_h = 0, row_h = 0, total_w = 0, total_h = 0, same_line = false }
end

local function UpdateLayout( bbox )
	-- Update row height
	if layout.same_line then
		if bbox.h > layout.row_h then
			layout.row_h = bbox.h
		end
	else
		layout.row_h = bbox.h
	end

	-- Calculate current layout w/h
	if bbox.x + bbox.w + margin > layout.total_w then
		layout.total_w = bbox.x + bbox.w + margin
	end

	if bbox.y + layout.row_h + margin > layout.total_h then
		layout.total_h = bbox.y + layout.row_h + margin
	end

	-- Update layout prev_x/y/w/h and same_line
	layout.prev_x = bbox.x
	layout.prev_y = bbox.y
	layout.prev_w = bbox.w
	layout.prev_h = bbox.h
	layout.same_line = false
end

function UI.Init()
	font.handle = lovr.graphics.newFont("ui/DejaVuSansMono.ttf")
end

function UI.SameLine()
	layout.same_line = true
end

function UI.Begin( name, x, y, z )
	local window = { id = Hash(name), x = x, y = y, z = z, w = 0, h = 0, command_list = {}, texture = nil, pass = nil }
	table.insert(windows, window)
end

function UI.End( main_pass )
	local cur_window = windows [#windows]
	cur_window.w = layout.total_w
	cur_window.h = layout.total_h
	cur_window.texture = lovr.graphics.newTexture(layout.total_w, layout.total_h, { mipmaps = false })
	cur_window.pass = lovr.graphics.getPass('render', { cur_window.texture })
	cur_window.pass:setFont(font.handle)
	cur_window.pass:setDepthTest(nil)
	cur_window.pass:setProjection(1, mat4():orthographic(cur_window.pass:getDimensions()))
	cur_window.pass:setColor(colors.window_bg)
	cur_window.pass:fill()

	for i, v in ipairs(cur_window.command_list) do
		if v.type == "rect_fill" then
			local m = lovr.math.newMat4(vec3(v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0), vec3(v.bbox.w, v.bbox.h, 0))
			cur_window.pass:setColor(colors.button_bg)
			cur_window.pass:plane(m, "fill")
		elseif v.type == "rect_wire" then
			local m = lovr.math.newMat4(vec3(v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0), vec3(v.bbox.w, v.bbox.h, 0))
			cur_window.pass:setColor(colors.button_border)
			cur_window.pass:plane(m, "line")
		elseif v.type == "circle_wire" then
			local m = lovr.math.newMat4(vec3(v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0), vec3(v.bbox.w/2, v.bbox.h/2, 0))
			cur_window.pass:setColor(colors.button_border)
			cur_window.pass:circle(m, "line")
		elseif v.type == "circle_fill" then
			local m = lovr.math.newMat4(vec3(v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0), vec3(v.bbox.w/3, v.bbox.h/3, 0))
			cur_window.pass:setColor(colors.button_border)
			cur_window.pass:circle(m, "fill")
		elseif v.type == "text" then
			cur_window.pass:setColor(colors.text)
			cur_window.pass:text(v.text, vec3(v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0))
		end
	end

	main_pass:setColor(1, 1, 1)
	main_pass:setMaterial(cur_window.texture)
	local window_m = lovr.math.newMat4(vec3(cur_window.x, cur_window.y, cur_window.z), vec3(cur_window.w * 0.01, cur_window.h * 0.01, 0))
	main_pass:plane(window_m, "fill")
	main_pass:setMaterial()

	ResetLayout()
	table.insert(passes, cur_window.pass)
end

function UI.BeginChild()
end

function UI.EndChild()
	ResetLayout()
end

function UI.NewFrame( main_pass )
	font.handle:setPixelDensity(1.0)
	DrawRay(main_pass)
end

function UI.RenderFrame( main_pass )
	table.insert(passes, main_pass)
	lovr.graphics.submit(passes)

	windows = nil
	windows = {}
	passes = nil
	passes = {}
end

function UI.Button( text, width, height )

	local text_w = font.handle:getWidth(text)
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = (2 * margin) + text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = (2 * margin) + text_w, h = (2 * margin) + text_h }
	end

	if width and type(width) == "number" and width > bbox.w then
		bbox.w = width
	end
	if height and type(height) == "number" and height > bbox.h then
		bbox.h = height
	end

	UpdateLayout(bbox)

	table.insert(windows [#windows].command_list, { type = "rect_fill", bbox = bbox })
	table.insert(windows [#windows].command_list, { type = "rect_wire", bbox = bbox })
	table.insert(windows [#windows].command_list, { type = "text", text = text, bbox = bbox })
end

function UI.CheckBox( text, checked )

	local char_w = font.handle:getWidth("W")
	local text_w = font.handle:getWidth(text)
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = text_h + margin + text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = text_h + margin + text_w, h = (2 * margin) + text_h }
	end

	UpdateLayout(bbox)

	local check_rect = { x = bbox.x, y = bbox.y + margin, w = text_h, h = text_h }
	local text_rect = { x = bbox.x + text_h + margin, y = bbox.y, w = text_w + margin, h = bbox.h }
	table.insert(windows [#windows].command_list, { type = "rect_wire", bbox = check_rect })
	table.insert(windows [#windows].command_list, { type = "text", text = text, bbox = text_rect })

	if checked and type(checked) == "boolean" then
		table.insert(windows [#windows].command_list, { type = "text", text = "✔", bbox = check_rect })
	end
end

function UI.RadioButton( text, group, checked )

	local char_w = font.handle:getWidth("W")
	local text_w = font.handle:getWidth(text)
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = text_h + margin + text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = text_h + margin + text_w, h = (2 * margin) + text_h }
	end

	UpdateLayout(bbox)

	local check_rect = { x = bbox.x, y = bbox.y + margin, w = text_h, h = text_h }
	local text_rect = { x = bbox.x + text_h + margin, y = bbox.y, w = text_w + margin, h = bbox.h }
	table.insert(windows [#windows].command_list, { type = "circle_wire", bbox = check_rect })
	table.insert(windows [#windows].command_list, { type = "text", text = text, bbox = text_rect })

	if checked and type(checked) == "boolean" then
		table.insert(windows [#windows].command_list, { type = "circle_fill", bbox = check_rect })
	end
end

return UI

-- button
-- checkbox
-- radiobutton
-- label
-- text input
-- list
local UI = {}

local last_off_x = -50000
local last_off_y = -50000
local ray = {}
local font = { handle, w, h, scale = 1 }
local margin = 14
local ui_scale = 0.005
local windows = {}
local passes = {}
local colors =
{
	text = { 0.8, 0.8, 0.8 },
	window_bg = { 0.26, 0.26, 0.26 },
	window_border = { 0.4, 0.4, 0.4 },
	button_bg = { 0.14, 0.14, 0.14 },
	button_bg_hover = { 0.19, 0.19, 0.19 },
	button_bg_click = { 0.12, 0.12, 0.12 },
	button_border = { 0, 0, 0 },
	check_border = { 0, 0, 0 },
	check_border_hover = { 0.5, 0.5, 0.5 },
	check_mark = { 0.3, 0.3, 1 },
	radio_border = { 0, 0, 0 },
	radio_border_hover = { 0.5, 0.5, 0.5 },
	radio_mark = { 0.3, 0.3, 1 },
	slider_bg = { 0.3, 0.3, 1 },
	slider_bg_hover = { 0.38, 0.38, 1 },
	slider_thumb = { 0.2, 0.2, 1 },
	list_bg = { 0.14, 0.14, 0.14 },
	list_border = { 0, 0, 0 },
	list_selected = { 0.3, 0.3, 1 },
}
local layout = { prev_x = 0, prev_y = 0, prev_w = 0, prev_h = 0, row_h = 0, total_w = 0, total_h = 0, same_line = false }

local function ClearTable( t )
	for i, v in ipairs(t) do
		t [i] = nil
	end
end

local function PointInRect( px, py, rx, ry, rw, rh )
	if px >= rx and px <= rx + rw and py >= ry and py <= ry + rh then
		return true
	end

	return false
end

local function MapRange( from_min, from_max, to_min, to_max, v )
	return (v - from_min) * (to_max - to_min) / (from_max - from_min) + to_min
end

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

local function Raycast( pos, dir, transform )
	local inverse = mat4(transform):invert()

	-- Transform ray into plane space
	pos = inverse * pos
	dir = (inverse * vec4(dir.x, dir.y, dir.z, 0)).xyz

	-- If ray is pointing backwards, no intersection
	if dir.z > -.001 then
		return nil
	else -- Otherwise, perform simplified plane projection
		return pos + dir * (pos.z / -dir.z)
	end
end

local function DrawRay( pass )
	pass:setColor(1, 0, 0)
	pass:sphere(ray.pos, .01)
	pass:setColor(1, 1, 1)
	pass:line(ray.pos, ray.pos + ray.dir * 100)
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

function UI.RayInfo()
	ray.pos = vec3(lovr.headset.getPosition("hand/left"))
	ray.dir = quat(lovr.headset.getOrientation("hand/left")):direction()
end

function UI.Init()
	font.handle = lovr.graphics.newFont("ui/DejaVuSansMono.ttf")
end

function UI.SameLine()
	layout.same_line = true
end

function UI.Begin( name, x, y, z )
	local window = { id = Hash(name), x = x, y = y, z = z, w = 0, h = 0, command_list = {}, texture = nil, pass = nil, is_hovered = false, off_x = 0, off_y = 0 }
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
			cur_window.pass:setColor(v.color)
			cur_window.pass:plane(m, "fill")
		elseif v.type == "rect_wire" then
			local m = lovr.math.newMat4(vec3(v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0), vec3(v.bbox.w, v.bbox.h, 0))
			cur_window.pass:setColor(v.color)
			cur_window.pass:plane(m, "line")
		elseif v.type == "circle_wire" then
			local m = lovr.math.newMat4(vec3(v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0), vec3(v.bbox.w / 2, v.bbox.h / 2, 0))
			cur_window.pass:setColor(v.color)
			cur_window.pass:circle(m, "line")
		elseif v.type == "circle_fill" then
			local m = lovr.math.newMat4(vec3(v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0), vec3(v.bbox.w / 3, v.bbox.h / 3, 0))
			cur_window.pass:setColor(v.color)
			cur_window.pass:circle(m, "fill")
		elseif v.type == "text" then
			cur_window.pass:setColor(v.color)
			cur_window.pass:text(v.text, vec3(v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0))
		end
	end

	main_pass:setColor(1, 1, 1)
	main_pass:setMaterial(cur_window.texture)
	local window_t = lovr.math.newMat4(cur_window.x, cur_window.y, cur_window.z)
	local hit = Raycast(ray.pos, ray.dir, window_t)
	local window_m = lovr.math.newMat4(window_t:scale(cur_window.w * ui_scale, cur_window.h * ui_scale))

	main_pass:plane(window_m, "fill")
	main_pass:setMaterial()

	if hit then
		if hit.x > -(cur_window.w * ui_scale) / 2 and hit.x < (cur_window.w * ui_scale) / 2 and hit.y > -(cur_window.h * ui_scale) / 2 and
			hit.y < (cur_window.h * ui_scale) / 2 then
			-- print(cur_window.w, hit.x)
			cur_window.is_hovered = true
			last_off_x = hit.x * (1 / ui_scale) + (cur_window.w / 2)
			last_off_y = -(hit.y * (1 / ui_scale) - (cur_window.h / 2))
		end
	end

	ResetLayout()
	table.insert(passes, cur_window.pass)
end

function UI.NewFrame( main_pass )
	font.handle:setPixelDensity(1.0)
	DrawRay(main_pass)
end

function UI.RenderFrame( main_pass )
	table.insert(passes, main_pass)
	lovr.graphics.submit(passes)

	-- windows = nil
	-- windows = {}
	-- passes = nil
	-- passes = {}
	ClearTable(windows)
	ClearTable(passes)
	-- collectgarbage("setstepmul",400)
	-- collectgarbage("collect")
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

	local result = false
	local col = colors.button_bg
	if PointInRect(last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h) then
		col = colors.button_bg_hover
		if lovr.headset.wasReleased("hand/left", "trigger") then
			result = true
		end
	end

	table.insert(windows [#windows].command_list, { type = "rect_fill", bbox = bbox, color = col })
	table.insert(windows [#windows].command_list, { type = "rect_wire", bbox = bbox, color = colors.button_border })
	table.insert(windows [#windows].command_list, { type = "text", text = text, bbox = bbox, color = colors.text })

	return result

end

function UI.ListBox( num_rows, max_chars, collection, sel_idx )
	local char_w = font.handle:getWidth("W")
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = (2 * margin) + (max_chars * char_w), h = (2 * margin) + (num_rows * text_h) }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = (2 * margin) + (max_chars * char_w), h = (2 * margin) + (num_rows * text_h) }
	end

	UpdateLayout(bbox)

	if PointInRect(last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h) then
		if lovr.headset.wasReleased("hand/left", "trigger") then

		end
	end

	table.insert(windows [#windows].command_list, { type = "rect_fill", bbox = bbox, color = colors.list_bg })
	table.insert(windows [#windows].command_list, { type = "rect_wire", bbox = bbox, color = colors.list_border })

	local offset = 0
	for i, v in ipairs(collection) do
		local str = v:sub(1, max_chars)
		table.insert(windows [#windows].command_list,
			{ type = "text", text = str, bbox = { x = bbox.x, y = bbox.y, w = (str:len() * char_w) + margin, h = text_h + offset }, color = colors.text })
		offset = offset + text_h + (2 * margin)
	end

end

function UI.Slider( text, v, v_min, v_max, width )
	local text_w = font.handle:getWidth(text)
	local text_h = font.handle:getHeight()
	local char_w = font.handle:getWidth("W")

	local slider_w = 10 * char_w
	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = slider_w + margin + text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = slider_w + margin + text_w, h = (2 * margin) + text_h }
	end

	if width and type(width) == "number" and width > bbox.w then
		bbox.w = width
		slider_w = width - margin - text_w
	end

	UpdateLayout(bbox)

	local thumb_w = text_h
	local col = colors.slider_bg
	if PointInRect(last_off_x, last_off_y, bbox.x, bbox.y, slider_w, bbox.h) then
		col = colors.slider_bg_hover
		if lovr.headset.isDown("hand/left", "trigger") then
			v = MapRange(bbox.x + 2, bbox.x + slider_w, v_min, v_max, last_off_x)
			if v >= v_min then
				v = math.ceil(v)
			else
				v = v_min
			end
		end
	end

	-- stupid way to turn -0 to 0 ???
	if v == 0 then v = 0 end

	local value_text_w = font.handle:getWidth(v)
	local text_label_rect = { x = bbox.x + slider_w + margin, y = bbox.y, w = text_w, h = bbox.h }
	local text_value_rect = { x = bbox.x, y = bbox.y, w = slider_w, h = bbox.h }
	local slider_rect = { x = bbox.x, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = slider_w, h = text_h }
	local thumb_pos = MapRange(v_min, v_max, bbox.x, bbox.x + slider_w - thumb_w, v)
	local thumb_rect = { x = thumb_pos, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = thumb_w, h = thumb_w }

	table.insert(windows [#windows].command_list, { type = "rect_fill", bbox = slider_rect, color = col })
	table.insert(windows [#windows].command_list, { type = "rect_fill", bbox = thumb_rect, color = colors.slider_thumb })
	table.insert(windows [#windows].command_list, { type = "text", text = text, bbox = text_label_rect, color = colors.text })
	table.insert(windows [#windows].command_list, { type = "text", text = v, bbox = text_value_rect, color = colors.text })
	return v
end

function UI.Label( text )
	local text_w = font.handle:getWidth(text)
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = text_w, h = (2 * margin) + text_h }
	end

	UpdateLayout(bbox)

	table.insert(windows [#windows].command_list, { type = "text", text = text, bbox = bbox, color = colors.text })
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

	local result = false
	local col = colors.check_border
	if PointInRect(last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h) then
		col = colors.check_border_hover
		if lovr.headset.wasReleased("hand/left", "trigger") then
			result = true
		end
	end

	local check_rect = { x = bbox.x, y = bbox.y + margin, w = text_h, h = text_h }
	local text_rect = { x = bbox.x + text_h + margin, y = bbox.y, w = text_w + margin, h = bbox.h }
	table.insert(windows [#windows].command_list, { type = "rect_wire", bbox = check_rect, color = col })
	table.insert(windows [#windows].command_list, { type = "text", text = text, bbox = text_rect, color = colors.text })

	if checked and type(checked) == "boolean" then
		table.insert(windows [#windows].command_list, { type = "text", text = "✔", bbox = check_rect, color = colors.check_mark })
	end

	return result
end

function UI.RadioButton( text, checked )

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

	local result = false
	local col = colors.radio_border
	if PointInRect(last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h) then
		col = colors.radio_border_hover
		if lovr.headset.wasReleased("hand/left", "trigger") then
			result = true
		end
	end

	local check_rect = { x = bbox.x, y = bbox.y + margin, w = text_h, h = text_h }
	local text_rect = { x = bbox.x + text_h + margin, y = bbox.y, w = text_w + margin, h = bbox.h }
	table.insert(windows [#windows].command_list, { type = "circle_wire", bbox = check_rect, color = col })
	table.insert(windows [#windows].command_list, { type = "text", text = text, bbox = text_rect, color = colors.text })

	if checked and type(checked) == "boolean" then
		table.insert(windows [#windows].command_list, { type = "circle_fill", bbox = check_rect, color = colors.radio_mark })
	end

	return result
end

return UI

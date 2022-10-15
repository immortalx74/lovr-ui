-- ------------------------------------------------------------------------------------------------------------------ --
--                        lovr-ui: An immediate mode VR GUI library for LOVR (https://lovr.org)                       --
--                                    Github: https://github.com/immortalx74/lovr-ui                                  --
-- ------------------------------------------------------------------------------------------------------------------ --

-- --------------------------------------------------- How to use --------------------------------------------------- --
-- * Put the ui folder inside your project and do UI = require "ui/ui"                                                --
-- * Initialize the library by calling 'UI.Init()' on lovr.load()                                                     --
-- * Handle controller input by calling 'UI.InputInfo()' on lovr.update()                                             --
-- * In lovr.draw(), call 'UI.NewFrame()' and 'UI.RenderFrame(pass)'                                                  --
-- * Everything inside NewFrame/RenderFrame is your GUI                                                               --
-- ------------------------------------------------------------------------------------------------------------------ --

-- -------------------------------------------------- How it works -------------------------------------------------- --
-- The general idea of an immediate mode ui is that creation, rendering and interaction of a widget is handled by a   --
-- single function call. e.g. calling 'if UI.Button("Click Me") then ...' creates and renders a button on the current --
-- window, and returns true if clicked. Those widget calls have to be  wrapped inside a 'UI.Begin()', 'UI.End()'      --
-- block which defines a single window.                                                                               --
-- Positioning of widgets is done by what is called an 'auto-layout'. All that does is calculate the total width and  --
-- height of the window and position the widgets with margins between them. In lovr-ui the layout is row-based, which --
-- means that every widget is placed bellow the previous one, unless you call 'UI.SameLine()'. That places the widget --
-- next to the previous one, instead of bellow. The height of the row is determined by the 'tallest' widget.          --
-- This kind of layout places some limits, e.g.:                                                                      --
-- ++++++++++++++++  ++++++++++                                                                                       --
-- +              +  +   2    +  <--- This is OK                                                                      --
-- +              +  ++++++++++                                                                                       --
-- +      1       +                                                                                                   --
-- +              +  ++++++++++                                                                                       --
-- +              +  +   3    +  <--- Can't do this. Can only be placed next to 2 or bellow 1                         --
-- ++++++++++++++++  ++++++++++                                                                                       --
-- This will be addressed in the future by allowing a Begin/End block to be nested inside another Begin/End block     --
--                                                                                                                    --
-- Immediate mode GUIs try to be stateless but some state is unavoidable. e.g. for ListBox and TextBox, scroll        --
-- position, selected index, cursor position, etc. are stored in global tables (listbox_state, textbox_state)         --
-- The whole GUI is created and destroyed every frame, and unlike retained mode GUIs, interaction happens at the end  --
-- of the frame. That means that there's always a 1 frame delay.                                                      --
-- Each widget, besides contributing to the layout, records draw-commands like rectangles, circles and text, that     --
-- describe how it will be drawn.                                                                                     --
-- On each 'UI.Begin()' call a new window of undetermined size is created and stored in the 'windows' table. A hash   --
-- using its name is calculated to uniquely identify it later. On 'UI.End()' the window size is calculated and an     --
-- associated texture is created. If the previous ID already exists (meaning the window was rendered for at least 1   --
-- frame), then the texture is never recreated, unless the window size has changed.                                   --
-- Then, the draw-commands are iterated and everything is drawn on the texture associated with the window.            --
-- Each window also acquires a pass which is then stored in another global table.                                     --
-- Finally, on 'UI.RenderFrame()' all window passes along with the main pass are submitted for LOVR to render them.   --
--                                                                                                                    --
-- Some notes:                                                                                                        --
-- * Widget sizes are mostly character-width based. This is done for simplicity. There are exceptions like Button,    --
--   which takes optional width/height parameters in pixels.                                                          --
-- * The correct way to handle input is to differentiate between 'active' and 'hot' widget. This is not currently     --
--   implemented. It's clearly wrong because if you interact with a slider and you hover on another slider, the second--
--   one becomes active (it shouldn't).                                                                               --
-- * The 'dominant' hand can be changed by clicking the corresponding trigger button. Scrolling in ListBoxes is done  --
--   by using the Y-axis of thumb stick.
------------------------------------------------------------------------------------------------------------------------

-- ------------------------------------------ Credits and acknowledgements ------------------------------------------ --
-- Bjorn Swenson (bjornbytes) - https://github.com/bjornbytes                                                         --
-- For creating the awesome LOVR framework, providing help and answering every single question!                       --
--                                                                                                                    --
-- Casey Muratori - https://caseymuratori.com/                                                                        --
-- For developing the immediate mode technique, coining the term, and creating the HandMade community.                --
--                                                                                                                    --
-- Omar Cornut - https://github.com/ocornut                                                                           --
-- For popularizing the concept with the outstanding Dear ImGui library.                                              --
--                                                                                                                    --
-- rxi - https://github.com/rxi                                                                                       --
-- For creating microui. The most tiny UI library from which lovr-ui was inspired from.                               --
-- ------------------------------------------------------------------------------------------------------------------ --
local UI = {}

local dominant_hand = "hand/right"
local hovered_window_id = nil
local focused_textbox = nil
local last_off_x = -50000
local last_off_y = -50000
local margin = 14
local ui_scale = 0.0005
local controller_vibrate = false
local font = { handle, w, h, scale = 1 }
local caret = { blink_rate = 50, counter = 0 }
local listbox_state = {}
local textbox_state = {}
local window_drag = { id = nil, is_dragging = false, offset = lovr.math.newMat4() }
local ray = {}
local windows = {}
local passes = {}
local textures = {}
local image_buttons = {}
local layout = { prev_x = 0, prev_y = 0, prev_w = 0, prev_h = 0, row_h = 0, total_w = 0, total_h = 0, same_line = false }
local input = { interaction_toggle_device = "hand/left", interaction_toggle_button = "thumbstick", interaction_enabled = true }
local colors =
{
	text = { 0.8, 0.8, 0.8 },
	window_bg = { 0.26, 0.26, 0.26 },
	window_border = { 0, 0, 0 },
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
	list_highlight = { 0.3, 0.3, 0.3 },
	textbox_bg = { 0.03, 0.03, 0.03 },
	textbox_bg_hover = { 0.11, 0.11, 0.11 },
	textbox_border = { 0.1, 0.1, 0.1 },
	textbox_border_focused = { 0.58, 0.58, 1 },
	image_button_border_highlight = { 0.5, 0.5, 0.5 }
}
local osk = { textures = {}, visible = false, prev_frame_visible = false, transform = lovr.math.newMat4(), mode = {}, cur_mode = 1 }
osk.mode[ 1 ] =
{
	"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
	"q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
	"a", "s", "d", "f", "g", "h", "j", "k", "l", ".",
	"shift", "z", "x", "c", "v", "b", "n", "m", ",", "backspace",
	"symbol", "left", "right", " ", " ", " ", "-", "_", "return", "return",
}

osk.mode[ 2 ] =
{
	"!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
	"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",
	"A", "S", "D", "F", "G", "H", "J", "K", "L", ":",
	"shift", "Z", "X", "C", "V", "B", "N", "M", "?", "backspace",
	"symbol", "left", "right", " ", " ", " ", "<", ">", "return", "return",
}

osk.mode[ 3 ] =
{
	"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
	"!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
	"+", "=", "[", "]", "{", "}", "\\", "|", "/", "`",
	"shift", "~", ",", ".", "<", ">", ";", ":", "\"", "backspace",
	"symbol", "left", "right", " ", " ", " ", "-", "_", "return", "return",
}
-- -------------------------------------------------------------------------- --
--                             Internals                                      --
-- -------------------------------------------------------------------------- --
local function Clamp( n, n_min, n_max )
	if n < n_min then n = n_min
	elseif n > n_max then n = n_max
	end

	return n
end

local function FindId( t, id )
	for i, v in ipairs( t ) do
		if v.id == id then
			return i
		end
	end
	return nil
end

local function ClearTable( t )
	for i, v in ipairs( t ) do
		t[ i ] = nil
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
	-- From: https://github.com/Alloyed/ltrie/blob/master/ltrie/lua_hashcode.lua
	local b = require 'bit'
	local t = type( o )
	if t == 'string' then
		local len = #o
		local h = len
		local step = b.rshift( len, 5 ) + 1

		for i = len, step, -step do
			h = b.bxor( h, b.lshift( h, 5 ) + b.rshift( h, 2 ) + string.byte( o, i ) )
		end
		return h
	elseif t == 'number' then
		local h = math.floor( o )
		if h ~= o then
			h = b.bxor( o * 0xFFFFFFFF )
		end
		while o > 0xFFFFFFFF do
			o = o / 0xFFFFFFFF
			h = b.bxor( h, o )
		end
		return h
	elseif t == 'bool' then
		return t and 1 or 2
	elseif t == 'table' and o.hashcode then
		local n = o:hashcode()
		assert( math.floor( n ) == n, "hashcode is not an integer" )
		return n
	end

	return nil
end

local function Raycast( pos, dir, transform )
	local inverse = mat4( transform ):invert()

	-- Transform ray into plane space
	pos = inverse * pos
	dir = (inverse * vec4( dir.x, dir.y, dir.z, 0 )).xyz

	-- If ray is pointing backwards, no intersection
	if dir.z > -.001 then
		return nil
	else -- Otherwise, perform simplified plane projection
		return pos + dir * (pos.z / -dir.z)
	end
end

local function DrawRay( pass )
	pass:setColor( 1, 0, 0 )
	pass:sphere( ray.pos, .01 )

	if ray.target then
		pass:setColor( 1, 1, 1 )
		pass:line( ray.pos, ray.hit and (ray.target * ray.hit) )
		pass:setColor( 0, 1, 0 )
		pass:sphere( ray.target * ray.hit, .005 )
	else
		pass:setColor( 1, 1, 1 )
		pass:line( ray.pos, ray.pos + ray.dir * 100 )
	end
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

local function ShowOSK( pass )
	if not osk.prev_frame_visible then
		local init_transform = lovr.math.newMat4( lovr.headset.getPose( "head" ) )
		init_transform:translate( vec3( 0, -0.3, -0.6 ) )
		osk.transform:set( init_transform )
	end

	osk.prev_frame_visible = true

	local window = { id = Hash( "OnScreenKeyboard" ), name = "OnScreenKeyboard", transform = osk.transform,
		w = 640, h = 320,
		command_list = {},
		texture = osk.textures[ osk.cur_mode ], pass = pass, is_hovered = false }
	table.insert( windows, window )

	local x_off
	local y_off

	if window.id == hovered_window_id then
		x_off = math.floor( last_off_x / 64 ) + 1
		y_off = math.floor( (last_off_y) / 64 )
		if lovr.headset.wasReleased( dominant_hand, "trigger" ) then
			if focused_textbox then
				lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
				local btn = osk.mode[ osk.cur_mode ][ math.floor( x_off + (y_off * 10) ) ]

				if btn == "shift" then
					if osk.cur_mode == 1 or osk.cur_mode == 3 then
						osk.cur_mode = 2
					else
						osk.cur_mode = 1
					end
				elseif btn == "symbol" then
					if osk.cur_mode == 1 or osk.cur_mode == 2 then
						osk.cur_mode = 3
					else
						osk.cur_mode = 1
					end
				elseif btn == "left" then
					focused_textbox.cursor = focused_textbox.cursor - 1
					if focused_textbox.cursor < focused_textbox.scroll - 1 then
						focused_textbox.scroll = focused_textbox.scroll - 1
						if focused_textbox.scroll < 1 then focused_textbox.scroll = 1 end
					end

					if focused_textbox.cursor < 0 then focused_textbox.cursor = 0 end
				elseif btn == "right" then
					focused_textbox.cursor = focused_textbox.cursor + 1
					if focused_textbox.cursor > focused_textbox.num_chars + focused_textbox.scroll - 1 then
						focused_textbox.scroll = focused_textbox.scroll + 1
						if focused_textbox.scroll > focused_textbox.text:len() - focused_textbox.num_chars then focused_textbox.scroll = focused_textbox.text:len() -
								focused_textbox.num_chars + 1
						end
					end
					if focused_textbox.cursor > focused_textbox.text:len() then focused_textbox.cursor = focused_textbox.text:len() end
				elseif btn == "return" then
					focused_textbox = nil
					osk.prev_frame_visible = false
					osk.visible = false
				elseif btn == "backspace" then
					if focused_textbox.cursor > 0 then
						local s1 = string.sub( focused_textbox.text, 1, focused_textbox.cursor - 1 )
						local s2 = string.sub( focused_textbox.text, focused_textbox.cursor + 1, -1 )
						focused_textbox.text = s1 .. s2
						focused_textbox.cursor = focused_textbox.cursor - 1
						if focused_textbox.scroll > focused_textbox.text:len() - focused_textbox.num_chars + 1 then
							focused_textbox.scroll = focused_textbox.scroll - 1
							if focused_textbox.scroll < 1 then focused_textbox.scroll = 1 end
						end
					end
				else
					local s1 = string.sub( focused_textbox.text, 1, focused_textbox.cursor )
					local s2 = string.sub( focused_textbox.text, focused_textbox.cursor + 1, -1 )
					focused_textbox.text = s1 .. btn .. s2
					focused_textbox.cursor = focused_textbox.cursor + 1
					if focused_textbox.cursor > focused_textbox.num_chars then
						focused_textbox.scroll = focused_textbox.scroll + 1
					end
				end
			end
		end
	end

	window.unscaled_transform = lovr.math.newMat4( window.transform )
	local window_m = lovr.math.newMat4( window.unscaled_transform:scale( window.w * ui_scale, window.h * ui_scale ) )

	-- Highlight hovered button
	if x_off then
		pass:setColor( 1, 1, 1 )
		local m = lovr.math.newMat4( window.transform ):translate( vec3( (-352 * ui_scale), 128 * ui_scale, 0.001 ) ) -- 320 + 32, 160 - 32

		-- Space and Return are wider
		local spc = x_off >= 4 and x_off <= 6 and y_off == 4
		local rtn = x_off >= 9 and x_off <= 10 and y_off == 4
		
		if spc then
			m:translate( 5 * 64 * ui_scale, -(y_off * 64 * ui_scale), 0 )
			m:scale( 192 * ui_scale, 64 * ui_scale, 1 )
		elseif rtn then
			m:translate( 9.5 * 64 * ui_scale, -(y_off * 64 * ui_scale), 0 )
			m:scale( 128 * ui_scale, 64 * ui_scale, 1 )
		else
			m:translate( x_off * 64 * ui_scale, -(y_off * 64 * ui_scale), 0 )
			m:scale( 64 * ui_scale, 64 * ui_scale, 1 )
		end

		pass:plane( m, "line" )
	end
	pass:setColor( 1, 1, 1 )
	pass:setMaterial( window.texture )
	pass:plane( window_m, "fill" )
	pass:setMaterial()
end

-- -------------------------------------------------------------------------- --
--                                User                                        --
-- -------------------------------------------------------------------------- --
function UI.GetWindowSize( name )
	local idx = FindId( windows, Hash( name ) )
	if idx ~= nil then
		return windows[ idx ].w * ui_scale, windows[ idx ].h * ui_scale
	end

	return nil
end

function UI.IsInteractionEnabled()
	return input.interaction_enabled
end

function UI.InputInfo()
	if lovr.headset.wasPressed( input.interaction_toggle_device, input.interaction_toggle_button ) then
		input.interaction_enabled = not input.interaction_enabled
		hovered_window_id = nil
	end

	if lovr.headset.wasPressed( "hand/left", "trigger" ) then
		dominant_hand = "hand/left"
	elseif lovr.headset.wasPressed( "hand/right", "trigger" ) then
		dominant_hand = "hand/right"
	end
	ray.pos = vec3( lovr.headset.getPosition( dominant_hand ) )
	ray.ori = quat( lovr.headset.getOrientation( dominant_hand ) )
	ray.dir = ray.ori:direction()

	caret.counter = caret.counter + 1
	if caret.counter > caret.blink_rate then caret.counter = 0 end
end

function UI.Init( interaction_toggle_device, interaction_toggle_button )
	input.interaction_toggle_device = interaction_toggle_device or input.interaction_toggle_device
	input.interaction_toggle_button = interaction_toggle_button or input.interaction_toggle_button
	font.handle = lovr.graphics.newFont( "ui/DejaVuSansMono.ttf" )
	osk.textures[ 1 ] = lovr.graphics.newTexture( "ui/keyboard1.png" )
	osk.textures[ 2 ] = lovr.graphics.newTexture( "ui/keyboard2.png" )
	osk.textures[ 3 ] = lovr.graphics.newTexture( "ui/keyboard3.png" )
end

function UI.NewFrame( main_pass )
	font.handle:setPixelDensity( 1.0 )
end

function UI.RenderFrame( main_pass )
	if input.interaction_enabled then
		if osk.visible then
			ShowOSK( main_pass )
		end

		local closest = math.huge
		local win_idx = nil

		for i, v in ipairs( windows ) do
			local hit = Raycast( ray.pos, ray.dir, v.transform )
			local dist = ray.pos:distance( v.transform:unpack( false ) )
			if hit and hit.x > -(windows[ i ].w * ui_scale) / 2 and hit.x < (windows[ i ].w * ui_scale) / 2 and
				hit.y > -(windows[ i ].h * ui_scale) / 2 and
				hit.y < (windows[ i ].h * ui_scale) / 2 then
				if dist < closest then
					win_idx = i
					closest = dist
				end
			end
		end

		if win_idx then
			local hit = Raycast( ray.pos, ray.dir, windows[ win_idx ].transform )
			ray.hit = hit
			hovered_window_id = windows[ win_idx ].id
			windows[ win_idx ].is_hovered = true
			ray.target = lovr.math.newMat4( windows[ win_idx ].transform )

			last_off_x = hit.x * (1 / ui_scale) + (windows[ win_idx ].w / 2)
			last_off_y = -(hit.y * (1 / ui_scale) - (windows[ win_idx ].h / 2))
		else
			ray.target = nil
			hovered_window_id = nil
		end

		DrawRay( main_pass )
	end

	table.insert( passes, main_pass )
	lovr.graphics.submit( passes )

	ClearTable( windows )
	ClearTable( passes )
	ray = nil
	ray = {}
end

function UI.SameLine()
	layout.same_line = true
end

function UI.Begin( name, transform )
	local window = { id = Hash( name ), name = name, transform = transform, w = 0, h = 0, command_list = {}, texture = nil, pass = nil, is_hovered = false }
	table.insert( windows, window )
end

function UI.End( main_pass )
	local cur_window = windows[ #windows ]
	cur_window.w = layout.total_w
	cur_window.h = layout.total_h

	local idx = FindId( textures, cur_window.id )
	if idx ~= nil then
		if cur_window.w == textures[ idx ].w and cur_window.h == textures[ idx ].h then
			cur_window.texture = textures[ idx ].texture
		else
			lovr.graphics.wait()
			textures[ idx ].texture:release()
			table.remove( textures, idx )
			local entry = { id = cur_window.id, w = layout.total_w, h = layout.total_h,
				texture = lovr.graphics.newTexture( layout.total_w, layout.total_h, { mipmaps = false } ), delete = true }
			cur_window.texture = entry.texture
			table.insert( textures, entry )
		end
	else
		local entry = { id = cur_window.id, w = layout.total_w, h = layout.total_h,
			texture = lovr.graphics.newTexture( layout.total_w, layout.total_h, { mipmaps = false } ) }
		cur_window.texture = entry.texture
		table.insert( textures, entry )
	end

	cur_window.pass = lovr.graphics.getPass( 'render', cur_window.texture )
	cur_window.pass:setFont( font.handle )
	cur_window.pass:setDepthTest( nil )
	cur_window.pass:setProjection( 1, mat4():orthographic( cur_window.pass:getDimensions() ) )
	cur_window.pass:setColor( colors.window_bg )
	cur_window.pass:fill()
	table.insert( windows[ #windows ].command_list,
		{ type = "rect_wire", bbox = { x = 0, y = 0, w = cur_window.w, h = cur_window.h }, color = colors.window_border } )

	for i, v in ipairs( cur_window.command_list ) do
		if v.type == "rect_fill" then
			local m = lovr.math.newMat4( vec3( v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0 ), vec3( v.bbox.w, v.bbox.h, 0 ) )
			cur_window.pass:setColor( v.color )
			cur_window.pass:plane( m, "fill" )
		elseif v.type == "rect_wire" then
			local m = lovr.math.newMat4( vec3( v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0 ), vec3( v.bbox.w, v.bbox.h, 0 ) )
			cur_window.pass:setColor( v.color )
			cur_window.pass:plane( m, "line" )
		elseif v.type == "circle_wire" then
			local m = lovr.math.newMat4( vec3( v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0 ), vec3( v.bbox.w / 2, v.bbox.h / 2, 0 ) )
			cur_window.pass:setColor( v.color )
			cur_window.pass:circle( m, "line" )
		elseif v.type == "circle_fill" then
			local m = lovr.math.newMat4( vec3( v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0 ), vec3( v.bbox.w / 3, v.bbox.h / 3, 0 ) )
			cur_window.pass:setColor( v.color )
			cur_window.pass:circle( m, "fill" )
		elseif v.type == "text" then
			cur_window.pass:setColor( v.color )
			cur_window.pass:text( v.text, vec3( v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0 ) )
		elseif v.type == "image" then
			-- NOTE Temp fix. Had to do negative vertical scale. Otherwise image gets flipped?
			local m = lovr.math.newMat4( vec3( v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0 ), vec3( v.bbox.w, -v.bbox.h, 0 ) )
			cur_window.pass:setColor( v.color )
			cur_window.pass:setMaterial( v.texture )
			cur_window.pass:plane( m, "fill" )
			cur_window.pass:setMaterial()
			cur_window.pass:setColor( 1, 1, 1 )
		end
	end

	main_pass:setColor( 1, 1, 1 )
	main_pass:setMaterial( cur_window.texture )
	cur_window.unscaled_transform = lovr.math.newMat4( cur_window.transform )

	if cur_window.id == hovered_window_id then
		if lovr.headset.wasPressed( dominant_hand, "grip" ) then
			window_drag.offset:set( mat4( ray.pos, ray.ori ):invert() * cur_window.transform )
		end
		if lovr.headset.isDown( dominant_hand, "grip" ) then
			window_drag.id = cur_window.id
			window_drag.is_dragging = true
		end
	end

	if lovr.headset.wasReleased( dominant_hand, "grip" ) then
		window_drag.id = nil
		window_drag.is_dragging = false
	end

	if window_drag.is_dragging and cur_window.id == window_drag.id then
		cur_window.transform:set( mat4( ray.pos, ray.ori ) * (window_drag.offset) )
	end

	local window_m = lovr.math.newMat4( cur_window.unscaled_transform:scale( cur_window.w * ui_scale, cur_window.h * ui_scale ) )

	main_pass:plane( window_m, "fill" )
	main_pass:setMaterial()

	ResetLayout()
	table.insert( passes, cur_window.pass )
end

function UI.ImageButton( img_filename, width, height )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. img_filename )
	local ib_idx = FindId( image_buttons, my_id )

	if ib_idx == nil then
		local tex = lovr.graphics.newTexture( img_filename )
		local ib = { id = my_id, img_filename = img_filename, texture = tex, w = width or tex:getWidth(), h = height or tex:getHeight() }
		table.insert( image_buttons, ib )
		return -- skip 1 frame
	end

	local ib = image_buttons[ ib_idx ]
	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = ib.w, h = ib.h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = ib.w, h = ib.h }
	end

	UpdateLayout( bbox )

	local result = false

	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == hovered_window_id then
		table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = bbox, color = colors.image_button_border_highlight } )
		if lovr.headset.wasReleased( dominant_hand, "trigger" ) then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			result = true
		end
	end

	table.insert( windows[ #windows ].command_list, { type = "image", bbox = bbox, texture = ib.texture, color = { 1, 1, 1 } } )

	return result
end

function UI.Button( text, width, height )
	local text_w = font.handle:getWidth( text )
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = (2 * margin) + text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = (2 * margin) + text_w, h = (2 * margin) + text_h }
	end

	if width and type( width ) == "number" and width > bbox.w then
		bbox.w = width
	end
	if height and type( height ) == "number" and height > bbox.h then
		bbox.h = height
	end

	UpdateLayout( bbox )

	local result = false
	local col = colors.button_bg
	local cur_window = windows[ #windows ]
	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == hovered_window_id then
		col = colors.button_bg_hover
		if lovr.headset.wasReleased( dominant_hand, "trigger" ) then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			result = true
		end
	end

	table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = bbox, color = col } )
	table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = bbox, color = colors.button_border } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = text, bbox = bbox, color = colors.text } )

	return result
end

function UI.TextBox( name, num_chars )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. name )
	local tb_idx = FindId( textbox_state, my_id )

	if tb_idx == nil then
		local tb = { id = my_id, text = "", scroll = 1, cursor = 0, num_chars = num_chars }
		table.insert( textbox_state, tb )
		return -- skip 1 frame
	end

	local text_h = font.handle:getHeight()
	local char_w = font.handle:getWidth( "W" )
	local label_w = font.handle:getWidth( name )

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = (4 * margin) + (num_chars * char_w) + label_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = (4 * margin) + (num_chars * char_w) + label_w, h = (2 * margin) + text_h }
	end

	UpdateLayout( bbox )

	local col1 = colors.textbox_bg
	local col2 = colors.textbox_border
	local cur_window = windows[ #windows ]
	local text_rect = { x = bbox.x, y = bbox.y, w = bbox.w - margin - label_w, h = bbox.h }
	local label_rect = { x = text_rect.x + text_rect.w + margin, y = bbox.y, w = label_w, h = bbox.h }

	if PointInRect( last_off_x, last_off_y, text_rect.x, text_rect.y, text_rect.w, text_rect.h ) and cur_window.id == hovered_window_id then
		col1 = colors.textbox_bg_hover
		if lovr.headset.wasReleased( dominant_hand, "trigger" ) then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			osk.visible = true
			focused_textbox = textbox_state[ tb_idx ]
		end
	end

	if focused_textbox and focused_textbox.id == my_id then col2 = colors.textbox_border_focused end

	local str = textbox_state[ tb_idx ].text:sub( 1, num_chars )

	if focused_textbox and focused_textbox.id == my_id then
		str = focused_textbox.text:sub( focused_textbox.scroll, focused_textbox.scroll + num_chars - 1 )
	end

	table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = text_rect, color = col1 } )
	table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = text_rect, color = col2 } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = str, bbox = { x = text_rect.x + margin, y = text_rect.y,
		w = (str:len() * char_w) + margin, h = text_rect.h }, color = colors.text } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = name, bbox = label_rect, color = colors.text } )

	-- caret
	if focused_textbox and focused_textbox.id == my_id and caret.counter % caret.blink_rate > (caret.blink_rate / 2) then
		table.insert( windows[ #windows ].command_list,
			{ type = "rect_fill",
				bbox = { x = text_rect.x + ((textbox_state[ tb_idx ].cursor - textbox_state[ tb_idx ].scroll + 1) * char_w) + margin + 8, y = text_rect.y + margin, w = 2,
					h = text_h },
				color = colors.text } )
	end

	return textbox_state[ tb_idx ].text
end

function UI.ListBox( name, num_rows, max_chars, collection )
	local cur_window = windows[ #windows ]
	local lst_idx = FindId( listbox_state, Hash( cur_window.name .. name ) )

	if lst_idx == nil then
		local l = { id = Hash( cur_window.name .. name ), scroll = 1, selected_idx = 1 }
		table.insert( listbox_state, l )
		return -- skip 1 frame
	end

	local char_w = font.handle:getWidth( "W" )
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = (2 * margin) + (max_chars * char_w), h = (num_rows * text_h) }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = (2 * margin) + (max_chars * char_w), h = (num_rows * text_h) }
	end

	UpdateLayout( bbox )

	local highlight_idx = nil
	local result = false

	local scrollmax = #collection - num_rows + 1
	if #collection < num_rows then scrollmax = 1 end
	if listbox_state[ lst_idx ].scroll > scrollmax then listbox_state[ lst_idx ].scroll = scrollmax end

	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == hovered_window_id then
		highlight_idx = math.floor( (last_off_y - bbox.y) / (text_h) ) + 1
		highlight_idx = Clamp( highlight_idx, 1, #collection )

		-- Select
		if lovr.headset.wasReleased( dominant_hand, "trigger" ) then
			listbox_state[ lst_idx ].selected_idx = highlight_idx + listbox_state[ lst_idx ].scroll - 1
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			result = true
		end

		-- Scroll
		local thumb_x, thumb_y = lovr.headset.getAxis( dominant_hand, "thumbstick" )
		if thumb_y > 0.7 then
			listbox_state[ lst_idx ].scroll = listbox_state[ lst_idx ].scroll - 1
			listbox_state[ lst_idx ].scroll = Clamp( listbox_state[ lst_idx ].scroll, 1, scrollmax )
		end

		if thumb_y < -0.7 then
			listbox_state[ lst_idx ].scroll = listbox_state[ lst_idx ].scroll + 1
			listbox_state[ lst_idx ].scroll = Clamp( listbox_state[ lst_idx ].scroll, 1, scrollmax )
		end
	end

	listbox_state[ lst_idx ].selected_idx = Clamp( listbox_state[ lst_idx ].selected_idx, 0, #collection )
	table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = bbox, color = colors.list_bg } )
	table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = bbox, color = colors.list_border } )

	-- Draw selected rect
	local lst_scroll = listbox_state[ lst_idx ].scroll
	local lst_selected_idx = listbox_state[ lst_idx ].selected_idx

	if lst_selected_idx >= lst_scroll and lst_selected_idx <= lst_scroll + num_rows then
		local selected_rect = { x = bbox.x, y = bbox.y + (lst_selected_idx - lst_scroll) * text_h, w = bbox.w, h = text_h }
		table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = selected_rect, color = colors.list_selected } )
	end

	-- Draw highlight when hovered
	if highlight_idx ~= nil then
		local highlight_rect = { x = bbox.x, y = bbox.y + ((highlight_idx - 1) * text_h), w = bbox.w, h = text_h }
		table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = highlight_rect, color = colors.list_highlight } )
	end

	local y_offset = bbox.y
	local last = lst_scroll + num_rows - 1
	if #collection < num_rows then
		last = #collection
	end

	for i = lst_scroll, last do
		local str = collection[ i ]:sub( 1, max_chars )
		table.insert( windows[ #windows ].command_list,
			{ type = "text", text = str, bbox = { x = bbox.x, y = y_offset, w = (str:len() * char_w) + margin, h = text_h }, color = colors.text } )
		y_offset = y_offset + text_h
	end

	return result
end

function UI.SliderInt( text, v, v_min, v_max, width )
	local text_w = font.handle:getWidth( text )
	local text_h = font.handle:getHeight()
	local char_w = font.handle:getWidth( "W" )

	local slider_w = 10 * char_w
	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = slider_w + margin + text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = slider_w + margin + text_w, h = (2 * margin) + text_h }
	end

	if width and type( width ) == "number" and width > bbox.w then
		bbox.w = width
		slider_w = width - margin - text_w
	end

	UpdateLayout( bbox )

	local thumb_w = text_h
	local col = colors.slider_bg
	local cur_window = windows[ #windows ]

	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, slider_w, bbox.h ) and cur_window.id == hovered_window_id then
		col = colors.slider_bg_hover
		if lovr.headset.isDown( dominant_hand, "trigger" ) then
			v = MapRange( bbox.x + 2, bbox.x + slider_w - 2, v_min, v_max, last_off_x )
		end

		if lovr.headset.wasPressed( dominant_hand, "trigger" ) then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
		end
	end

	v = Clamp( math.ceil( v ), v_min, v_max )
	-- stupid way to turn -0 to 0 ???
	if v == 0 then v = 0 end

	local value_text_w = font.handle:getWidth( v )
	local text_label_rect = { x = bbox.x + slider_w + margin, y = bbox.y, w = text_w, h = bbox.h }
	local text_value_rect = { x = bbox.x, y = bbox.y, w = slider_w, h = bbox.h }
	local slider_rect = { x = bbox.x, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = slider_w, h = text_h }
	local thumb_pos = MapRange( v_min, v_max, bbox.x, bbox.x + slider_w - thumb_w, v )
	local thumb_rect = { x = thumb_pos, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = thumb_w, h = thumb_w }

	table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = slider_rect, color = col } )
	table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = thumb_rect, color = colors.slider_thumb } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = text, bbox = text_label_rect, color = colors.text } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = v, bbox = text_value_rect, color = colors.text } )
	return v
end

function UI.SliderFloat( text, v, v_min, v_max, width, num_decimals )
	local text_w = font.handle:getWidth( text )
	local text_h = font.handle:getHeight()
	local char_w = font.handle:getWidth( "W" )

	local slider_w = 10 * char_w
	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = slider_w + margin + text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = slider_w + margin + text_w, h = (2 * margin) + text_h }
	end

	if width and type( width ) == "number" and width > bbox.w then
		bbox.w = width
		slider_w = width - margin - text_w
	end

	UpdateLayout( bbox )

	local thumb_w = text_h
	local col = colors.slider_bg
	local cur_window = windows[ #windows ]

	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, slider_w, bbox.h ) and cur_window.id == hovered_window_id then
		col = colors.slider_bg_hover
		if lovr.headset.isDown( dominant_hand, "trigger" ) then
			v = MapRange( bbox.x + 2, bbox.x + slider_w - 2, v_min, v_max, last_off_x )
		end

		if lovr.headset.wasPressed( dominant_hand, "trigger" ) then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
		end
	end

	v = Clamp( v, v_min, v_max )

	local value_text_w = font.handle:getWidth( v )
	local text_label_rect = { x = bbox.x + slider_w + margin, y = bbox.y, w = text_w, h = bbox.h }
	local text_value_rect = { x = bbox.x, y = bbox.y, w = slider_w, h = bbox.h }
	local slider_rect = { x = bbox.x, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = slider_w, h = text_h }
	local thumb_pos = MapRange( v_min, v_max, bbox.x, bbox.x + slider_w - thumb_w, v )
	local thumb_rect = { x = thumb_pos, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = thumb_w, h = thumb_w }
	num_decimals = num_decimals or 2
	local str_fmt = "%." .. num_decimals .. "f"

	table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = slider_rect, color = col } )
	table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = thumb_rect, color = colors.slider_thumb } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = text, bbox = text_label_rect, color = colors.text } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = string.format( str_fmt, v ), bbox = text_value_rect, color = colors.text } )
	return v
end

function UI.Label( text )
	local text_w = font.handle:getWidth( text )
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = text_w, h = (2 * margin) + text_h }
	end

	UpdateLayout( bbox )

	table.insert( windows[ #windows ].command_list, { type = "text", text = text, bbox = bbox, color = colors.text } )
end

function UI.CheckBox( text, checked )
	local char_w = font.handle:getWidth( "W" )
	local text_w = font.handle:getWidth( text )
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = text_h + margin + text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = text_h + margin + text_w, h = (2 * margin) + text_h }
	end

	UpdateLayout( bbox )

	local result = false
	local col = colors.check_border
	local cur_window = windows[ #windows ]
	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == hovered_window_id then
		col = colors.check_border_hover
		if lovr.headset.wasReleased( dominant_hand, "trigger" ) then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			result = true
		end
	end

	local check_rect = { x = bbox.x, y = bbox.y + margin, w = text_h, h = text_h }
	local text_rect = { x = bbox.x + text_h + margin, y = bbox.y, w = text_w + margin, h = bbox.h }
	table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = check_rect, color = col } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = text, bbox = text_rect, color = colors.text } )

	if checked and type( checked ) == "boolean" then
		table.insert( windows[ #windows ].command_list, { type = "text", text = "✔", bbox = check_rect, color = colors.check_mark } )
	end

	return result
end

function UI.RadioButton( text, checked )
	local char_w = font.handle:getWidth( "W" )
	local text_w = font.handle:getWidth( text )
	local text_h = font.handle:getHeight()

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = text_h + margin + text_w, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = text_h + margin + text_w, h = (2 * margin) + text_h }
	end

	UpdateLayout( bbox )

	local result = false
	local col = colors.radio_border
	local cur_window = windows[ #windows ]
	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == hovered_window_id then
		col = colors.radio_border_hover
		if lovr.headset.wasReleased( dominant_hand, "trigger" ) then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			result = true
		end
	end

	local check_rect = { x = bbox.x, y = bbox.y + margin, w = text_h, h = text_h }
	local text_rect = { x = bbox.x + text_h + margin, y = bbox.y, w = text_w + margin, h = bbox.h }
	table.insert( windows[ #windows ].command_list, { type = "circle_wire", bbox = check_rect, color = col } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = text, bbox = text_rect, color = colors.text } )

	if checked and type( checked ) == "boolean" then
		table.insert( windows[ #windows ].command_list, { type = "circle_fill", bbox = check_rect, color = colors.radio_mark } )
	end

	return result
end

return UI

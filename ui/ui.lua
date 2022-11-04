-- ------------------------------------------------------------------------------------------------------------------ --
--                        lovr-ui: An immediate mode VR GUI library for LOVR (https://lovr.org)                       --
--                                    Github: https://github.com/immortalx74/lovr-ui                                  --
-- ------------------------------------------------------------------------------------------------------------------ --

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

local root = (...):match( '(.-)[^%./]+$' ):gsub( '%.', '/' )

local e_trigger = {}
e_trigger.idle = 1
e_trigger.pressed = 2
e_trigger.down = 3
e_trigger.released = 4

local theme_changed = true
local activeID = nil
local hotID = nil
local dominant_hand = "hand/right"
local hovered_window_id = nil
local focused_textbox = nil
local focused_slider = nil
local last_off_x = -50000
local last_off_y = -50000
local margin = 14
local ui_scale = 0.0005
local new_scale = nil
local controller_vibrate = false
local image_buttons_default_ttl = 2
local whiteboards_default_ttl = 2
local font = { handle, w, h, scale = 1 }
local caret = { blink_rate = 50, counter = 0 }
local listbox_state = {}
local textbox_state = {}
local ray = {}
local windows = {}
local passes = {}
local textures = {}
local image_buttons = {}
local whiteboards = {}
local color_themes = {}
local window_drag = { id = nil, is_dragging = false, offset = lovr.math.newMat4() }
local layout = { prev_x = 0, prev_y = 0, prev_w = 0, prev_h = 0, row_h = 0, total_w = 0, total_h = 0, same_line = false }
local input = { interaction_toggle_device = "hand/left", interaction_toggle_button = "thumbstick", interaction_enabled = true, trigger = e_trigger.idle,
	pointer_rotation = math.pi / 3 }
local osk = { textures = {}, visible = false, prev_frame_visible = false, transform = lovr.math.newMat4(), mode = {}, cur_mode = 1, last_key = nil }

color_themes.dark =
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
	image_button_border_highlight = { 0.5, 0.5, 0.5 },
	tab_bar_bg = { 0.1, 0.1, 0.1 },
	tab_bar_border = { 0, 0, 0 },
	tab_bar_hover = { 0.2, 0.2, 0.2 },
	tab_bar_highlight = { 0.3, 0.3, 1 },
	progress_bar_bg = { 0.2, 0.2, 0.2 },
	progress_bar_fill = { 0.3, 0.3, 1 },
	progress_bar_border = { 0, 0, 0 },
	osk_mode_bg = { 0, 0, 0 },
	osk_highlight = { 1, 1, 1 }
}

color_themes.light =
{
	check_border = { 0.000, 0.000, 0.000 },
	check_border_hover = { 0.760, 0.760, 0.760 },
	textbox_bg_hover = { 0.570, 0.570, 0.570 },
	textbox_border = { 0.000, 0.000, 0.000 },
	text = { 0.120, 0.120, 0.120 },
	button_bg_hover = { 0.900, 0.900, 0.900 },
	radio_mark = { 0.172, 0.172, 0.172 },
	slider_bg = { 0.830, 0.830, 0.830 },
	progress_bar_fill = { 0.830, 0.830, 1.000 },
	progress_bar_bg = { 1.000, 1.000, 1.000 },
	tab_bar_highlight = { 0.151, 0.140, 1.000 },
	tab_bar_hover = { 0.802, 0.797, 0.795 },
	tab_bar_border = { 0.000, 0.000, 0.000 },
	tab_bar_bg = { 1.000, 0.994, 0.999 },
	image_button_border_highlight = { 0.500, 0.500, 0.500 },
	textbox_bg = { 0.700, 0.700, 0.700 },
	window_border = { 0.000, 0.000, 0.000 },
	window_bg = { 0.930, 0.930, 0.930 },
	button_bg = { 0.800, 0.800, 0.800 },
	progress_bar_border = { 0.000, 0.000, 0.000 },
	slider_bg_hover = { 0.870, 0.870, 0.870 },
	slider_thumb = { 0.700, 0.700, 0.700 },
	list_bg = { 0.877, 0.883, 0.877 },
	list_border = { 0.000, 0.000, 0.000 },
	list_selected = { 0.686, 0.687, 0.688 },
	list_highlight = { 0.808, 0.810, 0.811 },
	check_mark = { 0.000, 0.000, 0.000 },
	radio_border = { 0.000, 0.000, 0.000 },
	list_selected = { 0.686, 0.687, 0.688 },
	list_highlight = { 0.808, 0.810, 0.811 },
	check_mark = { 0.000, 0.000, 0.000 },
	radio_border = { 0.000, 0.000, 0.000 },
	radio_border_hover = { 0.760, 0.760, 0.760 },
	textbox_border_focused = { 0.000, 0.000, 1.000 },
	button_bg_click = { 0.120, 0.120, 0.120 },
	button_border = { 0.000, 0.000, 0.000 },
	osk_mode_bg = { 0.5, 0.5, 0.5 },
	osk_highlight = { 0.1, 0.1, 0.1 }
}

local colors = color_themes.dark

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

local function GetLineCount( str )
	-- https://stackoverflow.com/questions/24690910/how-to-get-lines-count-in-string/70137660#70137660
	local lines = 1
	for i = 1, #str do
		local c = str:sub( i, i )
		if c == '\n' then lines = lines + 1 end
	end

	return lines
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
	if ray.target then
		pass:setColor( 1, 1, 1 )
		pass:line( ray.pos, ray.hit and (ray.target * ray.hit) )
		pass:setColor( 0, 1, 0 )
		pass:sphere( ray.target * ray.hit, .004 )
	else
		pass:setColor( 1, 1, 1 )
		pass:line( ray.pos, ray.pos + ray.dir * 10 )
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

local function GenerateOSKTextures()
	-- TODO: Fix code repetition
	local passes = {}
	for md = 1, 3 do
		local p = lovr.graphics.getPass( 'render', osk.textures[ md ] )
		p:setFont( font.handle )
		p:setDepthTest( nil )
		p:setProjection( 1, mat4():orthographic( p:getDimensions() ) )
		p:setColor( colors.window_bg )
		p:fill()
		p:setColor( colors.window_border )
		p:plane( mat4( vec3( 320, 160, 0 ), vec3( 640, 320, 0 ) ), "line" )

		local x_off = 0
		local y_off = 32
		local count = 1

		for i, v in ipairs( osk.mode[ md ] ) do
			if i == 31 then
				local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
				p:setColor( colors.button_bg )
				if md == 2 then p:setColor( colors.osk_mode_bg ) end
				p:plane( m, "fill" )
				p:setColor( colors.button_border )
				p:plane( m, "line" )
				m:scale( vec3( 64 * ui_scale, 64 * ui_scale, 0 ) )
				p:setColor( colors.text )
				p:text( "⇧", m )
			elseif i == 40 then
				local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
				p:setColor( colors.button_bg )
				p:plane( m, "fill" )
				p:setColor( colors.button_border )
				p:plane( m, "line" )
				m:scale( vec3( 64 * ui_scale, 64 * ui_scale, 0 ) )
				p:setColor( colors.text )
				p:text( "⌫", m )
			elseif i == 41 then
				local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
				p:setColor( colors.button_bg )
				if md == 3 then p:setColor( colors.osk_mode_bg ) end
				p:plane( m, "fill" )
				p:setColor( colors.button_border )
				p:plane( m, "line" )
				m:scale( vec3( 22 * ui_scale, 22 * ui_scale, 0 ) )
				p:setColor( colors.text )
				p:text( "123?", m )
			elseif i == 42 then
				local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
				p:setColor( colors.button_bg )
				p:plane( m, "fill" )
				p:setColor( colors.button_border )
				p:plane( m, "line" )
				m:scale( vec3( 64 * ui_scale, 64 * ui_scale, 0 ) )
				p:setColor( colors.text )
				p:text( "←", m )
			elseif i == 43 then
				local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
				p:setColor( colors.button_bg )
				p:plane( m, "fill" )
				p:setColor( colors.button_border )
				p:plane( m, "line" )
				m:scale( vec3( 64 * ui_scale, 64 * ui_scale, 0 ) )
				p:setColor( colors.text )
				p:text( "→", m )
			elseif i == 45 then
				local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 184, 56, 0 ) )
				p:setColor( colors.button_bg )
				p:plane( m, "fill" )
				p:setColor( colors.button_border )
				p:plane( m, "line" )
				m:scale( vec3( 32 * ui_scale, 64 * ui_scale, 0 ) )
				p:setColor( colors.text )
				p:text( "̶", m )
			elseif i == 49 then
				local m = mat4( vec3( (count * 32) + x_off + 32, y_off, 0 ), vec3( 118, 56, 0 ) )
				p:setColor( colors.button_bg )
				p:plane( m, "fill" )
				p:setColor( colors.button_border )
				p:plane( m, "line" )
				m:scale( vec3( 32 * ui_scale, 64 * ui_scale, 0 ) )
				p:setColor( colors.text )
				p:text( "⏎", m )
			elseif i == 44 or i == 46 or i == 50 then -- skip those
			else
				local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
				p:setColor( colors.button_bg )
				p:plane( m, "fill" )
				p:setColor( colors.button_border )
				p:plane( m, "line" )
				m:scale( vec3( 32 * ui_scale, 32 * ui_scale, 0 ) )
				p:setColor( colors.text )
				p:text( v, m )
			end

			x_off = x_off + 32
			count = count + 1

			if i % 10 == 0 then
				y_off = y_off + 64
				x_off = 0
				count = 1
			end
		end

		p:plane( m, "fill" )
		table.insert( passes, p )
	end
	return passes
end

local function ShowOSK( pass )
	if not osk.prev_frame_visible then
		local init_transform = lovr.math.newMat4( lovr.headset.getPose( "head" ) )
		init_transform:translate( vec3( 0, -0.3, -0.6 ) )
		osk.transform:set( init_transform )
	end

	osk.prev_frame_visible = true
	osk.last_key = nil

	local window = { id = Hash( "OnScreenKeyboard" ), name = "OnScreenKeyboard", transform = osk.transform, w = 640, h = 320, command_list = {},
		texture = osk.textures[ osk.cur_mode ], pass = pass, is_hovered = false }

	table.insert( windows, 1, window ) -- NOTE: Insert on top. Does it make any difference?

	local x_off
	local y_off

	if window.id == hovered_window_id then
		x_off = math.floor( last_off_x / 64 ) + 1
		y_off = math.floor( (last_off_y) / 64 )
		if input.trigger == e_trigger.pressed then
			if focused_textbox or focused_slider then
				lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
				local btn = osk.mode[ osk.cur_mode ][ math.floor( x_off + (y_off * 10) ) ]

				if btn == "shift" then
					osk.last_key = nil
					if osk.cur_mode == 1 or osk.cur_mode == 3 then
						osk.cur_mode = 2
					else
						osk.cur_mode = 1
					end
				elseif btn == "symbol" then
					osk.last_key = nil
					if osk.cur_mode == 1 or osk.cur_mode == 2 then
						osk.cur_mode = 3
					else
						osk.cur_mode = 1
					end
				elseif btn == "left" then
					osk.last_key = "left"
				elseif btn == "right" then
					osk.last_key = "right"
				elseif btn == "return" then
					osk.last_key = "return"
					osk.prev_frame_visible = false
					osk.visible = false
					focused_textbox = nil
					focused_slider = nil
				elseif btn == "backspace" then
					osk.last_key = "backspace"
				else
					osk.last_key = btn
				end
			end
		end
	end

	window.unscaled_transform = lovr.math.newMat4( window.transform )
	local window_m = lovr.math.newMat4( window.unscaled_transform:scale( window.w * ui_scale, window.h * ui_scale ) )

	-- Highlight hovered button
	if x_off then
		pass:setColor( colors.osk_highlight )
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
function UI.GetScale()
	return ui_scale
end

function UI.SetScale( scale )
	new_scale = scale
end

function UI.SetTextBoxText( id, text )
	local idx = FindId( textbox_state, id )
	textbox_state[ idx ].text = text
	if textbox_state[ idx ].text:len() > textbox_state[ idx ].num_chars then
		textbox_state[ idx ].scroll = textbox_state[ idx ].text:len() - textbox_state[ idx ].num_chars + 1
	end
	textbox_state[ idx ].cursor = textbox_state[ idx ].text:len()
end

function UI.GetColorNames()
	local t = {}
	for i, v in pairs( colors ) do
		t[ #t + 1 ] = tostring( i )
	end
	return t
end

function UI.GetColor( col_name )
	return colors[ col_name ]
end

function UI.SetColor( col_name, color )
	colors[ col_name ] = color
	theme_changed = true
end

function UI.OverrideColor( col_name, color )
	colors[ col_name ] = color
end

function UI.SetColorTheme( theme, copy_from )
	if type( theme ) == "string" then
		colors = color_themes[ theme ]
	elseif type( theme ) == "table" then
		copy_from = copy_from or "dark"
		for i, v in pairs( color_themes[ copy_from ] ) do
			if theme[ i ] == nil then
				theme[ i ] = v
			end
		end
		colors = theme
	end

	theme_changed = true
end

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

function UI.SetInteractionEnabled( enabled )
	input.interaction_enabled = enabled
	if not enabled then
		hovered_window_id = nil
	end
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

	if lovr.headset.wasPressed( dominant_hand, "trigger" ) then
		input.trigger = e_trigger.pressed
	elseif lovr.headset.isDown( dominant_hand, "trigger" ) then
		input.trigger = e_trigger.down
	elseif lovr.headset.wasReleased( dominant_hand, "trigger" ) then
		input.trigger = e_trigger.released
	elseif not lovr.headset.wasReleased( dominant_hand, "trigger" ) then
		input.trigger = e_trigger.idle
	end

	ray.pos = vec3( lovr.headset.getPosition( dominant_hand ) )
	ray.ori = quat( lovr.headset.getOrientation( dominant_hand ) )
	local m = mat4( vec3( 0, 0, 0 ), ray.ori ):rotate( -input.pointer_rotation, 1, 0, 0 )
	ray.dir = quat( m ):direction()

	caret.counter = caret.counter + 1
	if caret.counter > caret.blink_rate then caret.counter = 0 end
	if input.trigger == e_trigger.pressed then
		activeID = nil
	end
end

function UI.Init( interaction_toggle_device, interaction_toggle_button, enabled, pointer_rotation )
	input.interaction_toggle_device = interaction_toggle_device or input.interaction_toggle_device
	input.interaction_toggle_button = interaction_toggle_button or input.interaction_toggle_button
	input.interaction_enabled = (enabled ~= false)
	input.pointer_rotation = pointer_rotation or input.pointer_rotation
	font.handle = lovr.graphics.newFont( root .. "DejaVuSansMono.ttf" )
	osk.textures[ 1 ] = lovr.graphics.newTexture( 640, 320, { mipmaps = false } )
	osk.textures[ 2 ] = lovr.graphics.newTexture( 640, 320, { mipmaps = false } )
	osk.textures[ 3 ] = lovr.graphics.newTexture( 640, 320, { mipmaps = false } )
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

	if theme_changed then
		for i, p in ipairs( GenerateOSKTextures() ) do
			table.insert( passes, p )
		end
		theme_changed = false
	end

	table.insert( passes, main_pass )
	lovr.graphics.submit( passes )

	if new_scale then
		ui_scale = new_scale
	end
	new_scale = nil

	ClearTable( windows )
	ClearTable( passes )
	ray = nil
	ray = {}

	if #image_buttons > 0 then
		for i = #image_buttons, 1, -1 do
			image_buttons[ i ].ttl = image_buttons[ i ].ttl - 1
			if image_buttons[ i ].ttl <= 0 then
				image_buttons[ i ].texture:release()
				image_buttons[ i ].texture = nil
				table.remove( image_buttons, i )
			end
		end
	end

	if #whiteboards > 0 then
		for i = #whiteboards, 1, -1 do
			whiteboards[ i ].ttl = whiteboards[ i ].ttl - 1
			if whiteboards[ i ].ttl <= 0 then
				whiteboards[ i ].texture:release()
				whiteboards[ i ].texture = nil
				table.remove( whiteboards, i )
			end
		end
	end
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

function UI.ProgressBar( progress, width )
	local char_w = font.handle:getWidth( "W" )
	local text_h = font.handle:getHeight()

	if width and width >= (2 * margin) + (4 * char_w) then
		width = width
	else
		width = 300
	end

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = width, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = width, h = (2 * margin) + text_h }
	end

	UpdateLayout( bbox )

	progress = Clamp( progress, 0, 100 )
	local fill_w = math.floor( (width * progress) / 100 )
	local str = progress .. "%"

	table.insert( windows[ #windows ].command_list,
		{ type = "rect_fill", bbox = { x = bbox.x, y = bbox.y, w = fill_w, h = bbox.h }, color = colors.progress_bar_fill } )
	table.insert( windows[ #windows ].command_list,
		{ type = "rect_fill", bbox = { x = bbox.x + fill_w, y = bbox.y, w = bbox.w - fill_w, h = bbox.h }, color = colors.progress_bar_bg } )
	table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = bbox, color = colors.progress_bar_border } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = str, bbox = bbox, color = colors.text } )
end

function UI.ImageButton( img_filename, width, height )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. img_filename )
	local ib_idx = FindId( image_buttons, my_id )

	if ib_idx == nil then
		local tex = lovr.graphics.newTexture( img_filename )
		local ib = { id = my_id, img_filename = img_filename, texture = tex, w = width or tex:getWidth(), h = height or tex:getHeight(),
			ttl = image_buttons_default_ttl }
		table.insert( image_buttons, ib )
		ib_idx = #image_buttons
	end

	local ib = image_buttons[ ib_idx ]
	ib.ttl = image_buttons_default_ttl

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = ib.w, h = ib.h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = ib.w, h = ib.h }
	end

	UpdateLayout( bbox )

	local result = false

	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == hovered_window_id then
		hotID = my_id
		table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = bbox, color = colors.image_button_border_highlight } )
		if input.trigger == e_trigger.pressed then
			activeID = my_id
		end
		if input.trigger == e_trigger.released and hotID == activeID then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			result = true
		end
	end

	table.insert( windows[ #windows ].command_list, { type = "image", bbox = bbox, texture = ib.texture, color = { 1, 1, 1 } } )

	return result
end

function UI.WhiteBoard( name, width, height )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. name )
	local wb_idx = FindId( whiteboards, my_id )

	if wb_idx == nil then
		local tex = lovr.graphics.newTexture( width, height, { mipmaps = false } )
		local wb = { id = my_id, texture = tex, w = width or tex:getWidth(), h = height or tex:getHeight(), ttl = whiteboards_default_ttl }
		table.insert( whiteboards, wb )
		wb_idx = #whiteboards
	end

	local wb = whiteboards[ wb_idx ]
	wb.ttl = whiteboards_default_ttl

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = wb.w, h = wb.h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = wb.w, h = wb.h }
	end

	UpdateLayout( bbox )

	local clicked = false
	local down = false
	local released = false
	local hovered = false
	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == hovered_window_id then
		hotID = my_id
		hovered = true
		if input.trigger == e_trigger.pressed then
			activeID = my_id
			clicked = true
		end
		if input.trigger == e_trigger.down and activeID == my_id then
			down = true
		end
		if input.trigger == e_trigger.released and hotID == activeID then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			released = true
		end
	end

	table.insert( windows[ #windows ].command_list, { type = "image", bbox = bbox, texture = wb.texture, color = { 1, 1, 1 } } )

	local p = lovr.graphics.getPass( "render", wb.texture )
	p:setDepthTest( nil )
	p:setProjection( 1, mat4():orthographic( p:getDimensions() ) )
	table.insert( passes, p )
	return p, clicked, down, released, hovered, last_off_x - bbox.x, last_off_y - bbox.y
end

function UI.Dummy( width, height )
	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = width, h = height }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = width, h = height }
	end

	UpdateLayout( bbox )
end

function UI.TabBar( name, tabs, idx )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. name )

	local text_h = font.handle:getHeight()
	local bbox = {}

	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = 0, h = (2 * margin) + text_h }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = 0, h = (2 * margin) + text_h }
	end

	local result = false, idx
	local total_w = 0
	local col = colors.tab_bar_bg
	local cur_window = windows[ #windows ]
	local x_off = bbox.x

	for i, v in ipairs( tabs ) do
		local text_w = font.handle:getWidth( v )
		local tab_w = text_w + (2 * margin)
		bbox.w = bbox.w + tab_w

		if PointInRect( last_off_x, last_off_y, x_off, bbox.y, tab_w, bbox.h ) and cur_window.id == hovered_window_id then
			hotID = my_id
			col = colors.tab_bar_hover
			if input.trigger == e_trigger.pressed then
				activeID = my_id
			end
			if input.trigger == e_trigger.released and hotID == activeID then
				lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
				idx = i
				result = true
			end
		else
			col = colors.tab_bar_bg
		end

		local tab_rect = { x = x_off, y = bbox.y, w = tab_w, h = bbox.h }
		table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = tab_rect, color = col } )
		table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = tab_rect, color = colors.tab_bar_border } )
		table.insert( windows[ #windows ].command_list, { type = "text", text = v, bbox = tab_rect, color = colors.text } )

		if idx == i then
			table.insert( windows[ #windows ].command_list,
				{ type = "rect_fill", bbox = { x = tab_rect.x + 2, y = tab_rect.y + tab_rect.h - 6, w = tab_rect.w - 4, h = 5 }, color = colors.tab_bar_highlight } )
		end
		x_off = x_off + tab_w
	end

	table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = bbox, color = colors.tab_bar_border } )
	UpdateLayout( bbox )

	return result, idx
end

function UI.Button( text, width, height )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. text )

	local text_w = font.handle:getWidth( text )
	local text_h = font.handle:getHeight()
	local num_lines = GetLineCount( text )

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = (2 * margin) + text_w, h = (2 * margin) + (num_lines * text_h) }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = (2 * margin) + text_w, h = (2 * margin) + (num_lines * text_h) }
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
		hotID = my_id
		col = colors.button_bg_hover
		if input.trigger == e_trigger.pressed then
			activeID = my_id
		end
		if input.trigger == e_trigger.released and hotID == activeID then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			result = true
		end
	end

	table.insert( windows[ #windows ].command_list, { type = "rect_fill", bbox = bbox, color = col } )
	table.insert( windows[ #windows ].command_list, { type = "rect_wire", bbox = bbox, color = colors.button_border } )
	table.insert( windows[ #windows ].command_list, { type = "text", text = text, bbox = bbox, color = colors.text } )

	return result
end

function UI.TextBox( name, num_chars, buffer )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. name )
	local tb_idx = FindId( textbox_state, my_id )

	if tb_idx == nil then
		local tb = { id = my_id, text = buffer, scroll = 1, cursor = buffer:len(), num_chars = num_chars }
		table.insert( textbox_state, tb )
		tb_idx = #textbox_state
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
	local got_focus = false

	if PointInRect( last_off_x, last_off_y, text_rect.x, text_rect.y, text_rect.w, text_rect.h ) and cur_window.id == hovered_window_id then
		hotID = my_id
		col1 = colors.textbox_bg_hover
		if input.trigger == e_trigger.pressed then
			activeID = my_id
		end
		if input.trigger == e_trigger.released and hotID == activeID then
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
			osk.visible = true
			focused_textbox = textbox_state[ tb_idx ]
			got_focus = true
		end
	end

	local str = textbox_state[ tb_idx ].text:sub( 1, num_chars )
	local buffer_changed = false

	if focused_textbox and focused_textbox.id == my_id then
		col2 = colors.textbox_border_focused
		if osk.last_key then
			if osk.last_key == "left" then
				focused_textbox.cursor = focused_textbox.cursor - 1
				if focused_textbox.cursor < focused_textbox.scroll - 1 then
					focused_textbox.scroll = focused_textbox.scroll - 1
					if focused_textbox.scroll < 1 then focused_textbox.scroll = 1 end
				end
				if focused_textbox.cursor < 0 then focused_textbox.cursor = 0 end
			elseif osk.last_key == "right" then
				focused_textbox.cursor = focused_textbox.cursor + 1
				if focused_textbox.cursor > focused_textbox.num_chars + focused_textbox.scroll - 1 then
					focused_textbox.scroll = focused_textbox.scroll + 1
					if focused_textbox.scroll > focused_textbox.text:len() - focused_textbox.num_chars then
						focused_textbox.scroll = focused_textbox.text:len() - focused_textbox.num_chars + 1
					end
				end
				if focused_textbox.cursor > focused_textbox.text:len() then focused_textbox.cursor = focused_textbox.text:len() end
			elseif osk.last_key == "backspace" then
				if focused_textbox.cursor > 0 then
					buffer_changed = true
					local s1 = string.sub( focused_textbox.text, 1, focused_textbox.cursor - 1 )
					local s2 = string.sub( focused_textbox.text, focused_textbox.cursor + 1, -1 )
					focused_textbox.text = s1 .. s2
					focused_textbox.cursor = focused_textbox.cursor - 1
					if focused_textbox.scroll > focused_textbox.text:len() - focused_textbox.num_chars + 1 then
						focused_textbox.scroll = focused_textbox.scroll - 1
						if focused_textbox.scroll < 1 then focused_textbox.scroll = 1 end
					end
				end
			elseif osk.last_key == "return" then
				return got_focus, buffer_changed, my_id, textbox_state[ tb_idx ].text
			else
				buffer_changed = true
				local s1 = string.sub( focused_textbox.text, 1, focused_textbox.cursor )
				local s2 = string.sub( focused_textbox.text, focused_textbox.cursor + 1, -1 )
				focused_textbox.text = s1 .. osk.last_key .. s2
				focused_textbox.cursor = focused_textbox.cursor + 1
				if focused_textbox.cursor > focused_textbox.num_chars then
					focused_textbox.scroll = focused_textbox.scroll + 1
				end
			end

		end
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

	return got_focus, buffer_changed, my_id, textbox_state[ tb_idx ].text
end

function UI.ListBox( name, num_rows, max_chars, collection )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. name )
	local lst_idx = FindId( listbox_state, my_id )

	if lst_idx == nil then
		local l = { id = my_id, scroll = 1, selected_idx = 1 }
		table.insert( listbox_state, l )
		lst_idx = #listbox_state
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
		hotID = my_id
		highlight_idx = math.floor( (last_off_y - bbox.y) / (text_h) ) + 1
		highlight_idx = Clamp( highlight_idx, 1, #collection )

		-- Select
		if input.trigger == e_trigger.pressed then
			activeID = my_id
		end
		if input.trigger == e_trigger.released and hotID == activeID then
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

	return result, listbox_state[ lst_idx ].selected_idx
end

function UI.SliderInt( text, v, v_min, v_max, width )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. text )

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

	-- Silently replace with a textbox
	if focused_slider == my_id then
		bbox.w = -margin
		UpdateLayout( bbox )
		UI.SameLine()
		local gf, bc, id, txt
		gf, bc, id, txt = UI.TextBox( text, (slider_w - (3 * margin)) / char_w, tostring( v ) )

		if bc then
			if tonumber( txt ) then
				v = tonumber( txt )
			end
			if osk.last_key == "return" then
				focused_slider = nil
				focused_textbox = nil
			end
			return true, v
		else
			return false, v
		end
	else -- Remove redundant state. Might not be called ever again
		local tb_idx = FindId( textbox_state, my_id )
		if tb_idx then
			table.remove( textbox_state, tb_idx )
		end
	end

	UpdateLayout( bbox )

	local thumb_w = text_h
	local col = colors.slider_bg
	local cur_window = windows[ #windows ]
	local result = false

	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, slider_w, bbox.h ) and cur_window.id == hovered_window_id then
		hotID = my_id
		col = colors.slider_bg_hover

		if input.trigger == e_trigger.pressed then
			activeID = my_id
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
		end
	end

	if not lovr.headset.isDown( dominant_hand, "grip" ) then
		if input.trigger == e_trigger.down and activeID == my_id then
			v = MapRange( bbox.x + 2, bbox.x + slider_w - 2, v_min, v_max, last_off_x )
		end

		if input.trigger == e_trigger.released and activeID == my_id then
			result = true
		end

		v = Clamp( math.ceil( v ), v_min, v_max )
		-- stupid way to turn -0 to 0 ???
		if v == 0 then v = 0 end
	else
		if input.trigger == e_trigger.pressed and activeID == my_id then
			focused_slider = my_id
		end
	end

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
	return result, v
end

function UI.SliderFloat( text, v, v_min, v_max, width, num_decimals )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. text )

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

	-- Silently replace with a textbox
	if focused_slider == my_id then
		bbox.w = -margin
		UpdateLayout( bbox )
		UI.SameLine()
		local gf, bc, id, txt
		num_decimals = num_decimals or 2
		local str_fmt = "%." .. num_decimals .. "f"
		gf, bc, id, txt = UI.TextBox( text, (slider_w - (3 * margin)) / char_w, string.format( str_fmt, tostring( v ) ) )

		if bc then
			if tonumber( txt ) then
				v = tonumber( txt )
			end
			if osk.last_key == "return" then
				focused_slider = nil
				focused_textbox = nil
			end
			return true, v
		else
			return false, v
		end
	else -- Remove redundant state. Might not be called ever again
		local tb_idx = FindId( textbox_state, my_id )
		if tb_idx then
			table.remove( textbox_state, tb_idx )
		end
	end

	UpdateLayout( bbox )

	local thumb_w = text_h
	local col = colors.slider_bg
	local cur_window = windows[ #windows ]
	local result = false

	if PointInRect( last_off_x, last_off_y, bbox.x, bbox.y, slider_w, bbox.h ) and cur_window.id == hovered_window_id then
		hotID = my_id
		col = colors.slider_bg_hover

		if input.trigger == e_trigger.pressed then
			activeID = my_id
			lovr.headset.vibrate( dominant_hand, 0.3, 0.1 )
		end
	end

	if not lovr.headset.isDown( dominant_hand, "grip" ) then
		if input.trigger == e_trigger.down and activeID == my_id then
			v = MapRange( bbox.x + 2, bbox.x + slider_w - 2, v_min, v_max, last_off_x )
		end

		if input.trigger == e_trigger.released and activeID == my_id then
			result = true
		end

		v = Clamp( v, v_min, v_max )
	else
		if input.trigger == e_trigger.pressed and activeID == my_id then
			focused_slider = my_id
		end
	end

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
	return result, v
end

function UI.Label( text )
	local text_w = font.handle:getWidth( text )
	local text_h = font.handle:getHeight()
	local num_lines = GetLineCount( text )

	local bbox = {}
	if layout.same_line then
		bbox = { x = layout.prev_x + layout.prev_w + margin, y = layout.prev_y, w = text_w, h = (2 * margin) + (num_lines * text_h) }
	else
		bbox = { x = margin, y = layout.prev_y + layout.row_h + margin, w = text_w, h = (2 * margin) + (num_lines * text_h) }
	end

	UpdateLayout( bbox )

	table.insert( windows[ #windows ].command_list, { type = "text", text = text, bbox = bbox, color = colors.text } )
end

function UI.CheckBox( text, checked )
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. text )

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
		hotID = my_id
		col = colors.check_border_hover

		if input.trigger == e_trigger.pressed then
			activeID = my_id
		end
		if input.trigger == e_trigger.released and hotID == activeID then
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
	local cur_window = windows[ #windows ]
	local my_id = Hash( cur_window.name .. text )

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
		hotID = my_id
		col = colors.radio_border_hover

		if input.trigger == e_trigger.pressed then
			activeID = my_id
		end
		if input.trigger == e_trigger.released and hotID == activeID then
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

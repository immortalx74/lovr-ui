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

UI._ = {}

local _ = UI._ --Allias for shorter access

_.e_trigger = {}
_.e_trigger.idle = 1
_.e_trigger.pressed = 2
_.e_trigger.down = 3
_.e_trigger.released = 4

_.theme_changed = true
_.activeID = nil
_.hotID = nil
_.modal_window = nil
_.dominant_hand = "hand/right"
_.hovered_window_id = nil
_.focused_textbox = nil
_.focused_slider = nil
_.widget_counter = nil
_.last_off_x = -50000
_.last_off_y = -50000
_.margin = 14
_.separator_thickness = 4
_.ui_scale = 0.0005
_.new_scale = nil
_.controller_vibrate = false
_.image_buttons_default_ttl = 2
_.whiteboards_default_ttl = 2
_.utf8 = {}
_.font = { handle = nil, w = nil, h = nil, scale = 1 }
_.caret = { blink_rate = 50, counter = 0 }
_.listbox_state = {}
_.textbox_state = {}
_.ray = {}
_.windows = {}
_.passes = {}
_.textures = {}
_.image_buttons = {}
_.whiteboards = {}
_.layout = { prev_x = 0, prev_y = 0, prev_w = 0, prev_h = 0, row_h = 0, total_w = 0, total_h = 0, same_line = false, same_column = false }
_.input = {
	interaction_toggle_device = "hand/left",
	interaction_toggle_button = "thumbstick",
	interaction_enabled = true,
	trigger = _.e_trigger.idle,
	pointer_rotation = math.pi / 3
}
local osk = {
	visible = false,
	prev_frame_visible = false,
	transform = lovr.math.newMat4(),
	packs = {},
	cur_mode = 1,
	cur_pack = 1,
	last_key = nil
}
local clamp_sampler = lovr.graphics.newSampler( { wrap = 'clamp' } )
local color_themes = {}
local texture_flags = { mipmaps = true, usage = { 'sample', 'render', 'transfer' } }
local window_drag = { id = nil, is_dragging = false, offset = lovr.math.newMat4() }

osk.packs[ 1 ] = { mode = {}, textures = {} }

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
	osk_highlight = { 1, 1, 1 },
	modal_tint = { 0.3, 0.3, 0.3 },
	separator = { 0, 0, 0 }
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
	radio_border_hover = { 0.760, 0.760, 0.760 },
	textbox_border_focused = { 0.000, 0.000, 1.000 },
	button_bg_click = { 0.120, 0.120, 0.120 },
	button_border = { 0.000, 0.000, 0.000 },
	osk_mode_bg = { 0.5, 0.5, 0.5 },
	osk_highlight = { 0.1, 0.1, 0.1 },
	modal_tint = { 0.15, 0.15, 0.15 },
	separator = { 0.5, 0.5, 0.5 }
}

_.colors = color_themes.dark

osk.packs[ 1 ].mode[ 1 ] =
{
	"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
	"q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
	"a", "s", "d", "f", "g", "h", "j", "k", "l", ".",
	"shift", "z", "x", "c", "v", "b", "n", "m", ",", "backspace",
	"symbol", "left", "right", " ", " ", " ", "-", "_", "return", "return",
}

osk.packs[ 1 ].mode[ 2 ] =
{
	"!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
	"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",
	"A", "S", "D", "F", "G", "H", "J", "K", "L", ":",
	"shift", "Z", "X", "C", "V", "B", "N", "M", "?", "backspace",
	"symbol", "left", "right", " ", " ", " ", "<", ">", "return", "return",
}

osk.packs[ 1 ].mode[ 3 ] =
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
function _.Clamp( n, n_min, n_max )
	if n < n_min then
		n = n_min
	elseif n > n_max then
		n = n_max
	end

	return n
end

function _.GetLineCount( str )
	-- https://stackoverflow.com/questions/24690910/how-to-get-lines-count-in-string/70137660#70137660
	local lines = 1
	for i = 1, #str do
		local c = str:sub( i, i )
		if c == '\n' then lines = lines + 1 end
	end

	return lines
end

function _.FindId( t, id )
	for i, v in ipairs( t ) do
		if v.id == id then
			return i
		end
	end
	return nil
end

function _.ClearTable( t )
	for i, v in ipairs( t ) do
		t[ i ] = nil
	end
end

function _.PointInRect( px, py, rx, ry, rw, rh )
	if px >= rx and px <= rx + rw and py >= ry and py <= ry + rh then
		return true
	end

	return false
end

function _.MapRange( from_min, from_max, to_min, to_max, v )
	return (v - from_min) * (to_max - to_min) / (from_max - from_min) + to_min
end

function _.Hash( o )
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

function _.Raycast( pos, dir, transform )
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

function _.DrawRay( pass )
	if _.ray.target then
		pass:setColor( 1, 1, 1 )
		pass:line( _.ray.pos, _.ray.hit and (_.ray.target * _.ray.hit) )
		pass:setColor( 0, 1, 0 )
		pass:sphere( _.ray.target * _.ray.hit, .004 )
	else
		pass:setColor( 1, 1, 1 )
		pass:line( _.ray.pos, _.ray.pos + _.ray.dir * 10 )
	end
end

function _.ResetLayout()
	_.layout = { prev_x = 0, prev_y = 0, prev_w = 0, prev_h = 0, row_h = 0, total_w = 0, total_h = 0, same_line = false, same_column = false }
end

function _.UpdateLayout( bbox )
	-- Update row height
	if _.layout.same_line then
		if bbox.h > _.layout.row_h then
			_.layout.row_h = bbox.h
		end
	elseif _.layout.same_column then
		if bbox.h + _.layout.prev_h + _.margin < _.layout.row_h then
			_.layout.row_h = _.layout.row_h - _.layout.prev_h - _.margin
		else
			_.layout.row_h = bbox.h
		end
	else
		_.layout.row_h = bbox.h
	end

	-- Calculate current _.layout w/h
	if bbox.x + bbox.w + _.margin > _.layout.total_w then
		_.layout.total_w = bbox.x + bbox.w + _.margin
	end

	if bbox.y + _.layout.row_h + _.margin > _.layout.total_h then
		_.layout.total_h = bbox.y + _.layout.row_h + _.margin
	end

	-- Update _.layout prev_x/y/w/h and same_line
	_.layout.prev_x = bbox.x
	_.layout.prev_y = bbox.y
	_.layout.prev_w = bbox.w
	_.layout.prev_h = bbox.h
	_.layout.same_line = false
	_.layout.same_column = false

	_.widget_counter = _.widget_counter + 1
end

local function GenerateOSKTextures()
	-- TODO: Fix code repetition
	local passes = {}
	for pk = 1, #osk.packs do
		for md = 1, 3 do
			local p = lovr.graphics.newPass( osk.packs[ pk ].textures[ md ] )
			p:setFont( _.font.handle )
			p:setDepthTest( nil )
			p:setProjection( 1, mat4():orthographic( p:getDimensions() ) )
			p:setColor( _.colors.window_bg )
			p:fill()
			p:setColor( _.colors.window_border )
			p:plane( mat4( vec3( 320, 160, 0 ), vec3( 640, 320, 0 ) ), "line" )

			local x_off = 0
			local y_off = 32
			local count = 1

			for i, v in ipairs( osk.packs[ pk ].mode[ md ] ) do
				if i == 31 then
					local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
					p:setColor( _.colors.button_bg )
					if md == 2 then p:setColor( _.colors.osk_mode_bg ) end
					p:plane( m, "fill" )
					p:setColor( _.colors.button_border )
					p:plane( m, "line" )
					m:scale( vec3( 64 * _.ui_scale, 64 * _.ui_scale, 0 ) )
					p:setColor( _.colors.text )
					p:text( "⇧", m )
				elseif i == 40 then
					local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
					p:setColor( _.colors.button_bg )
					p:plane( m, "fill" )
					p:setColor( _.colors.button_border )
					p:plane( m, "line" )
					m:scale( vec3( 64 * _.ui_scale, 64 * _.ui_scale, 0 ) )
					p:setColor( _.colors.text )
					p:text( "⌫", m )
				elseif i == 41 then
					local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
					p:setColor( _.colors.button_bg )
					if md == 3 then p:setColor( _.colors.osk_mode_bg ) end
					p:plane( m, "fill" )
					p:setColor( _.colors.button_border )
					p:plane( m, "line" )
					m:scale( vec3( 22 * _.ui_scale, 22 * _.ui_scale, 0 ) )
					p:setColor( _.colors.text )
					p:text( "123?", m )
				elseif i == 42 then
					local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
					p:setColor( _.colors.button_bg )
					p:plane( m, "fill" )
					p:setColor( _.colors.button_border )
					p:plane( m, "line" )
					m:scale( vec3( 64 * _.ui_scale, 64 * _.ui_scale, 0 ) )
					p:setColor( _.colors.text )
					p:text( "←", m )
				elseif i == 43 then
					local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
					p:setColor( _.colors.button_bg )
					p:plane( m, "fill" )
					p:setColor( _.colors.button_border )
					p:plane( m, "line" )
					m:scale( vec3( 64 * _.ui_scale, 64 * _.ui_scale, 0 ) )
					p:setColor( _.colors.text )
					p:text( "→", m )
				elseif i == 45 then
					local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 184, 56, 0 ) )
					p:setColor( _.colors.button_bg )
					p:plane( m, "fill" )
					p:setColor( _.colors.button_border )
					p:plane( m, "line" )
					m:scale( vec3( 32 * _.ui_scale, 64 * _.ui_scale, 0 ) )
					p:setColor( _.colors.text )
					p:text( "̶", m )
				elseif i == 49 then
					local m = mat4( vec3( (count * 32) + x_off + 32, y_off, 0 ), vec3( 118, 56, 0 ) )
					p:setColor( _.colors.button_bg )
					p:plane( m, "fill" )
					p:setColor( _.colors.button_border )
					p:plane( m, "line" )
					m:scale( vec3( 32 * _.ui_scale, 64 * _.ui_scale, 0 ) )
					p:setColor( _.colors.text )
					p:text( "⏎", m )
				elseif i == 44 or i == 46 or i == 50 then -- skip those
				else
					local m = mat4( vec3( (count * 32) + x_off, y_off, 0 ), vec3( 56, 56, 0 ) )
					p:setColor( _.colors.button_bg )
					p:plane( m, "fill" )
					p:setColor( _.colors.button_border )
					p:plane( m, "line" )
					m:scale( vec3( 32 * _.ui_scale, 32 * _.ui_scale, 0 ) )
					p:setColor( _.colors.text )
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
			table.insert( _.passes, p )
		end
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

	local window = {
		id = _.Hash( "OnScreenKeyboard" ),
		name = "OnScreenKeyboard",
		transform = osk.transform,
		w = 640,
		h = 320,
		command_list = {},
		texture = osk.packs[ osk.cur_pack ].textures[ osk.cur_mode ],
		pass = pass,
		is_hovered = false
	}

	table.insert( _.windows, 1, window ) -- NOTE: Insert on top. Does it make any difference?

	local x_off
	local y_off

	if window.id == _.hovered_window_id then
		x_off = math.floor( _.last_off_x / 64 ) + 1
		y_off = math.floor( (_.last_off_y) / 64 )
		if _.input.trigger == _.e_trigger.pressed then
			if _.focused_textbox or _.focused_slider then
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
				local btn = osk.packs[ osk.cur_pack ].mode[ osk.cur_mode ][ math.floor( x_off + (y_off * 10) ) ]

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
					_.focused_textbox = nil
					_.focused_slider = nil
				elseif btn == "backspace" then
					osk.last_key = "backspace"
				else
					if lovr.headset.isDown( _.dominant_hand, "grip" ) and btn == " " then
						if osk.cur_pack < #osk.packs then
							osk.cur_pack = osk.cur_pack + 1
						else
							osk.cur_pack = 1
						end
					else
						osk.last_key = btn
					end
				end
			end
		end
	end

	window.unscaled_transform = lovr.math.newMat4( window.transform )
	local window_m = lovr.math.newMat4( window.unscaled_transform:scale( window.w * _.ui_scale, window.h * _.ui_scale ) )

	-- Highlight hovered button
	if x_off then
		pass:setColor( _.colors.osk_highlight )
		local m = lovr.math.newMat4( window.transform ):translate( vec3( (-352 * _.ui_scale), 128 * _.ui_scale, 0.001 ) ) -- 320 + 32, 160 - 32

		-- Space and Return are wider
		local spc = x_off >= 4 and x_off <= 6 and y_off == 4
		local rtn = x_off >= 9 and x_off <= 10 and y_off == 4

		if spc then
			m:translate( 5 * 64 * _.ui_scale, -(y_off * 64 * _.ui_scale), 0 )
			m:scale( 192 * _.ui_scale, 64 * _.ui_scale, 1 )
		elseif rtn then
			m:translate( 9.5 * 64 * _.ui_scale, -(y_off * 64 * _.ui_scale), 0 )
			m:scale( 128 * _.ui_scale, 64 * _.ui_scale, 1 )
		else
			m:translate( x_off * 64 * _.ui_scale, -(y_off * 64 * _.ui_scale), 0 )
			m:scale( 64 * _.ui_scale, 64 * _.ui_scale, 1 )
		end

		pass:plane( m, "line" )
	end
	pass:setColor( 1, 1, 1 )
	pass:setMaterial( window.texture )
	pass:plane( window_m, "fill" )
	pass:setMaterial()
end

-- Partially embeded functions from https://github.com/meepen/Lua-5.1-UTF-8
-- License: Creative Commons Zero v1.0 Universal
function _.utf8.strRelToAbs( str, ... )
	local args = { ... }

	for k, v in ipairs( args ) do
		v = v > 0 and v or #str + v + 1
		if v < 1 or v > #str then
			error( "bad index to string (out of range)", 3 )
		end
		args[ k ] = v
	end

	return unpack( args )
end

function _.utf8.decode( str, startPos )
	startPos = _.utf8.strRelToAbs( str, startPos or 1 )
	local b1 = str:byte( startPos, startPos )

	-- Single-byte sequence
	if b1 < 0x80 then
		return startPos, startPos
	end

	-- Validate first byte of multi-byte sequence
	if b1 > 0xF4 or b1 < 0xC2 then
		return nil
	end

	-- Get 'supposed' amount of continuation bytes from primary byte
	local contByteCount = b1 >= 0xF0 and 3 or
		b1 >= 0xE0 and 2 or
		b1 >= 0xC0 and 1

	local endPos = startPos + contByteCount

	-- Validate our continuation bytes
	for _, bX in ipairs { str:byte( startPos + 1, endPos ) } do
		if bit.band( bX, 0xC0 ) ~= 0x80 then
			return nil
		end
	end

	return startPos, endPos
end

function _.utf8.len( str, startPos, endPos )
	if str == "" then return 0 end
	startPos, endPos = _.utf8.strRelToAbs( str, startPos or 1, endPos or -1 )
	local len = 0

	repeat
		local seqStartPos, seqEndPos = _.utf8.decode( str, startPos )

		-- Hit an invalid sequence?
		if not seqStartPos then
			return false, startPos
		end

		-- Increment current string pointer
		startPos = seqEndPos + 1

		-- Increment length
		len = len + 1
	until seqEndPos >= endPos

	return len
end

function _.utf8.offset( str, n, startPos )
	startPos = _.utf8.strRelToAbs( str, startPos or (n >= 0 and 1) or #str )

	-- Find the beginning of the sequence over startPos
	if n == 0 then
		for i = startPos, 1, -1 do
			local seqStartPos, seqEndPos = _.utf8.decode( str, i )
			if seqStartPos then
				return seqStartPos
			end
		end
		return nil
	end

	if not _.utf8.decode( str, startPos ) then
		error( "initial position is not beginning of a valid sequence", 2 )
	end

	local itStart, itEnd, itStep = nil, nil, nil

	if n > 0 then -- Find the beginning of the n'th sequence forwards
		itStart = startPos
		itEnd = #str
		itStep = 1
	else -- Find the beginning of the n'th sequence backwards
		n = -n
		itStart = startPos
		itEnd = 1
		itStep = -1
	end

	for i = itStart, itEnd, itStep do
		local seqStartPos, seqEndPos = _.utf8.decode( str, i )
		if seqStartPos then
			n = n - 1
			if n == 0 then
				return seqStartPos
			end
		end
	end

	return nil
end

function _.utf8.sub( text, s_pos, e_pos )
	if e_pos == -1 then
		e_pos = _.utf8.len( text, 1, -1 )
	end
	if s_pos > e_pos then
		return ""
	end

	local start_offset_byte = _.utf8.offset( text, s_pos )
	local end_offset_byte = _.utf8.offset( text, e_pos )

	if end_offset_byte == nil then
		end_offset_byte = e_pos
	end

	local char_start, char_end = _.utf8.decode( text, end_offset_byte )

	if char_end == nil then
		char_end = 0
		char_start = 0
	end

	local count = char_end - char_start
	local str = text:sub( start_offset_byte, end_offset_byte + count )
	return str
end

-- -------------------------------------------------------------------------- --
--                                User                                        --
-- -------------------------------------------------------------------------- --
function UI.EndModalWindow()
	_.modal_window = nil
end

function UI.AddKeyboardPack( lower_case, upper_case, symbols )
	local md = {}
	md[ 1 ] = lower_case
	md[ 2 ] = upper_case
	md[ 3 ] = symbols

	local t = {}
	t[ 1 ] = lovr.graphics.newTexture( 640, 320, texture_flags )
	t[ 2 ] = lovr.graphics.newTexture( 640, 320, texture_flags )
	t[ 3 ] = lovr.graphics.newTexture( 640, 320, texture_flags )

	osk.packs[ #osk.packs + 1 ] = { mode = md, textures = t }
	GenerateOSKTextures()
end

function UI.GetScale()
	return _.ui_scale
end

function UI.SetScale( scale )
	_.new_scale = scale
end

function UI.SetTextBoxText( id, text )
	local idx = _.FindId( _.textbox_state, id )
	_.textbox_state[ idx ].text = text
	if _.utf8.len( _.textbox_state[ idx ].text, 1 ) > _.textbox_state[ idx ].num_visible_chars then
		_.textbox_state[ idx ].scroll = _.utf8.len( _.textbox_state[ idx ].text, 1 ) - _.textbox_state[ idx ].num_visible_chars + 1
	end
	_.textbox_state[ idx ].cursor = _.textbox_state[ idx ].text:len()
end

function UI.GetColorNames()
	local t = {}
	for i, v in pairs( _.colors ) do
		t[ #t + 1 ] = tostring( i )
	end
	return t
end

function UI.GetColor( col_name )
	return _.colors[ col_name ]
end

function UI.SetColor( col_name, color )
	_.colors[ col_name ] = color
	_.theme_changed = true
end

function UI.OverrideColor( col_name, color )
	_.colors[ col_name ] = color
end

function UI.SetColorTheme( theme, copy_from )
	if type( theme ) == "string" then
		_.colors = color_themes[ theme ]
	elseif type( theme ) == "table" then
		copy_from = copy_from or "dark"
		for i, v in pairs( color_themes[ copy_from ] ) do
			if theme[ i ] == nil then
				theme[ i ] = v
			end
		end
		_.colors = theme
	end

	_.theme_changed = true
end

function UI.GetWindowSize( name )
	local idx = _.FindId( _.windows, _.Hash( name ) )
	if idx ~= nil then
		return _.windows[ idx ].w * _.ui_scale, _.windows[ idx ].h * _.ui_scale
	end

	return nil
end

function UI.IsInteractionEnabled()
	return _.input.interaction_enabled
end

function UI.SetInteractionEnabled( enabled )
	_.input.interaction_enabled = enabled
	if not enabled then
		_.hovered_window_id = nil
	end
end

function UI.InputInfo( emulated_headset, ray_position, ray_orientation )
	if lovr.headset.wasPressed( _.input.interaction_toggle_device, _.input.interaction_toggle_button ) then
		_.input.interaction_enabled = not _.input.interaction_enabled
		_.hovered_window_id = nil
	end

	if lovr.headset.wasPressed( "hand/left", "trigger" ) then
		_.dominant_hand = "hand/left"
	elseif lovr.headset.wasPressed( "hand/right", "trigger" ) then
		_.dominant_hand = "hand/right"
	end

	if lovr.headset.wasPressed( _.dominant_hand, "trigger" ) then
		_.input.trigger = _.e_trigger.pressed
	elseif lovr.headset.isDown( _.dominant_hand, "trigger" ) then
		_.input.trigger = _.e_trigger.down
	elseif lovr.headset.wasReleased( _.dominant_hand, "trigger" ) then
		_.input.trigger = _.e_trigger.released
	elseif not lovr.headset.wasReleased( _.dominant_hand, "trigger" ) then
		_.input.trigger = _.e_trigger.idle
	end

	if emulated_headset then
		if ray_position and ray_orientation then
			_.ray.pos = vec3( ray_position.x, ray_position.y, ray_position.z )
			_.ray.ori = quat( ray_orientation )
			local m = mat4( vec3( 0, 0, 0 ), _.ray.ori ):rotate( 0, 1, 0, 0 )
			_.ray.dir = quat( m ):direction()
		else
			_.ray.pos = vec3( lovr.headset.getPosition( "head" ) )
			_.ray.ori = quat( lovr.headset.getOrientation( "head" ) )
			local m = mat4( vec3( 0, 0, 0 ), _.ray.ori ):rotate( 0, 1, 0, 0 )
			_.ray.dir = quat( m ):direction()
		end
	else
		_.ray.pos = vec3( lovr.headset.getPosition( _.dominant_hand ) )
		_.ray.ori = quat( lovr.headset.getOrientation( _.dominant_hand ) )
		local m = mat4( vec3( 0, 0, 0 ), _.ray.ori ):rotate( -_.input.pointer_rotation, 1, 0, 0 )
		_.ray.dir = quat( m ):direction()
	end

	_.caret.counter = _.caret.counter + 1
	if _.caret.counter > _.caret.blink_rate then _.caret.counter = 0 end
	if _.input.trigger == _.e_trigger.pressed then
		_.activeID = nil
	end
end

function UI.Init( interaction_toggle_device, interaction_toggle_button, enabled, pointer_rotation )
	_.input.interaction_toggle_device = interaction_toggle_device or _.input.interaction_toggle_device
	_.input.interaction_toggle_button = interaction_toggle_button or _.input.interaction_toggle_button
	_.input.interaction_enabled = (enabled ~= false)
	_.input.pointer_rotation = pointer_rotation or _.input.pointer_rotation
	_.font.handle = lovr.graphics.newFont( root .. "DejaVuSansMono.ttf" )
	osk.packs[ 1 ].textures[ 1 ] = lovr.graphics.newTexture( 640, 320, texture_flags )
	osk.packs[ 1 ].textures[ 2 ] = lovr.graphics.newTexture( 640, 320, texture_flags )
	osk.packs[ 1 ].textures[ 3 ] = lovr.graphics.newTexture( 640, 320, texture_flags )
end

function UI.NewFrame( main_pass )
	_.font.handle:setPixelDensity( 1.0 )
	if _.new_scale then
		_.ui_scale = _.new_scale
	end
	_.new_scale = nil

	_.ClearTable( _.windows )
	_.ClearTable( _.passes )

	if #_.image_buttons > 0 then
		for i = #_.image_buttons, 1, -1 do
			_.image_buttons[ i ].ttl = _.image_buttons[ i ].ttl - 1
			if _.image_buttons[ i ].ttl <= 0 then
				_.image_buttons[ i ].texture:release()
				_.image_buttons[ i ].texture = nil
				table.remove( _.image_buttons, i )
			end
		end
	end

	if #_.whiteboards > 0 then
		for i = #_.whiteboards, 1, -1 do
			_.whiteboards[ i ].ttl = _.whiteboards[ i ].ttl - 1
			if _.whiteboards[ i ].ttl <= 0 then
				_.whiteboards[ i ].texture:release()
				_.whiteboards[ i ].texture = nil
				table.remove( _.whiteboards, i )
			end
		end
	end
end

function UI.RenderFrame( main_pass )
	if _.input.interaction_enabled then
		if osk.visible then
			ShowOSK( main_pass )
		end

		local closest = math.huge
		local win_idx = nil

		for i, v in ipairs( _.windows ) do
			local hit = _.Raycast( _.ray.pos, _.ray.dir, v.transform )
			local dist = _.ray.pos:distance( v.transform:unpack( false ) )
			if hit and hit.x > -(_.windows[ i ].w * _.ui_scale) / 2 and hit.x < (_.windows[ i ].w * _.ui_scale) / 2 and
				hit.y > -(_.windows[ i ].h * _.ui_scale) / 2 and
				hit.y < (_.windows[ i ].h * _.ui_scale) / 2 then
				if dist < closest then
					win_idx = i
					closest = dist
				end
			end
		end

		if win_idx then
			local hit = _.Raycast( _.ray.pos, _.ray.dir, _.windows[ win_idx ].transform )
			_.ray.hit = hit
			_.hovered_window_id = _.windows[ win_idx ].id
			_.windows[ win_idx ].is_hovered = true
			_.ray.target = lovr.math.newMat4( _.windows[ win_idx ].transform )

			_.last_off_x = hit.x * (1 / _.ui_scale) + (_.windows[ win_idx ].w / 2)
			_.last_off_y = -(hit.y * (1 / _.ui_scale) - (_.windows[ win_idx ].h / 2))
		else
			_.ray.target = nil
			_.hovered_window_id = nil
		end

		_.DrawRay( main_pass )
	end

	if _.theme_changed then
		for i, p in ipairs( GenerateOSKTextures() ) do
			table.insert( _.passes, p )
		end
		_.theme_changed = false
	end

	return _.passes
end

function UI.SameLine()
	_.layout.same_line = true
end

function UI.SameColumn()
	_.layout.same_column = true
end

function UI.Begin( name, transform, is_modal )
	local window = {
		id = _.Hash( name ),
		name = name,
		transform = transform,
		w = 0,
		h = 0,
		command_list = {},
		texture = nil,
		pass = nil,
		is_hovered = false,
		is_modal = is_modal or false
	}
	table.insert( _.windows, window )
	if is_modal then
		_.modal_window = window.id
	end
	_.widget_counter = 1
end

function UI.End( main_pass )
	local cur_window = _.windows[ #_.windows ]
	cur_window.w = _.layout.total_w
	cur_window.h = _.layout.total_h

	local idx = _.FindId( _.textures, cur_window.id )
	if idx ~= nil then
		if cur_window.w == _.textures[ idx ].w and cur_window.h == _.textures[ idx ].h then
			cur_window.texture = _.textures[ idx ].texture
		else
			lovr.graphics.wait()
			_.textures[ idx ].texture:release()
			table.remove( _.textures, idx )
			local entry = {
				id = cur_window.id,
				w = _.layout.total_w,
				h = _.layout.total_h,
				texture = lovr.graphics.newTexture( _.layout.total_w, _.layout.total_h, texture_flags ),
				delete = true
			}
			cur_window.texture = entry.texture
			table.insert( _.textures, entry )
		end
	else
		local entry = {
			id = cur_window.id,
			w = _.layout.total_w,
			h = _.layout.total_h,
			texture = lovr.graphics.newTexture( _.layout.total_w, _.layout.total_h, texture_flags )
		}
		cur_window.texture = entry.texture
		table.insert( _.textures, entry )
	end

	cur_window.pass = lovr.graphics.newPass( cur_window.texture )
	cur_window.pass:setFont( _.font.handle )
	cur_window.pass:setDepthTest( nil )
	cur_window.pass:setProjection( 1, mat4():orthographic( cur_window.pass:getDimensions() ) )
	cur_window.pass:setColor( _.colors.window_bg )
	cur_window.pass:fill()
	table.insert( _.windows[ #_.windows ].command_list,
		{ type = "rect_wire", bbox = { x = 0, y = 0, w = cur_window.w, h = cur_window.h }, color = _.colors.window_border } )

	for i, v in ipairs( cur_window.command_list ) do
		if v.type == "rect_fill" then
			if v.is_separator then
				cur_window.pass:setColor( v.color )
				local m = lovr.math.newMat4( vec3( v.bbox.x + (cur_window.w / 2), v.bbox.y, 0 ), vec3( cur_window.w - (2 * _.margin), _.separator_thickness, 0 ) )
				cur_window.pass:plane( m, "fill" )
			else
				cur_window.pass:setColor( v.color )
				local m = lovr.math.newMat4( vec3( v.bbox.x + (v.bbox.w / 2), v.bbox.y + (v.bbox.h / 2), 0 ), vec3( v.bbox.w, v.bbox.h, 0 ) )
				cur_window.pass:plane( m, "fill" )
			end
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
			cur_window.pass:setSampler( clamp_sampler )
			cur_window.pass:plane( m, "fill" )
			cur_window.pass:setMaterial()
			cur_window.pass:setColor( 1, 1, 1 )
		end
	end

	main_pass:setColor( 1, 1, 1 )
	if _.modal_window and cur_window.id ~= _.modal_window then
		main_pass:setColor( _.colors.modal_tint )
	end
	main_pass:setMaterial( cur_window.texture )
	cur_window.unscaled_transform = lovr.math.newMat4( cur_window.transform )

	if cur_window.id == _.hovered_window_id and not window_drag.is_dragging then
		if lovr.headset.wasPressed( _.dominant_hand, "grip" ) then
			window_drag.offset:set( mat4( _.ray.pos, _.ray.ori ):invert() * cur_window.transform )
			window_drag.id = cur_window.id
			window_drag.is_dragging = true
		end
	end

	if lovr.headset.wasReleased( _.dominant_hand, "grip" ) then
		window_drag.id = nil
		window_drag.is_dragging = false
	end

	if window_drag.is_dragging and cur_window.id == window_drag.id then
		cur_window.transform:set( mat4( _.ray.pos, _.ray.ori ) * (window_drag.offset) )
	end

	local window_m = lovr.math.newMat4( cur_window.unscaled_transform:scale( cur_window.w * _.ui_scale, cur_window.h * _.ui_scale ) )

	main_pass:plane( window_m, "fill" )
	main_pass:setMaterial()

	_.ResetLayout()
	table.insert( _.passes, cur_window.pass )
end

function UI.ProgressBar( progress, width )
	local char_w = _.font.handle:getWidth( "W" )
	local text_h = _.font.handle:getHeight()

	if width and width >= (2 * _.margin) + (4 * char_w) then
		width = width
	else
		width = 300
	end

	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = width, h = (2 * _.margin) + text_h }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = width, h = (2 * _.margin) + text_h }
	end

	_.UpdateLayout( bbox )

	progress = _.Clamp( progress, 0, 100 )
	local fill_w = math.floor( (width * progress) / 100 )
	local str = progress .. "%"

	table.insert( _.windows[ #_.windows ].command_list,
		{ type = "rect_fill", bbox = { x = bbox.x, y = bbox.y, w = fill_w, h = bbox.h }, color = _.colors.progress_bar_fill } )
	table.insert( _.windows[ #_.windows ].command_list,
		{ type = "rect_fill", bbox = { x = bbox.x + fill_w, y = bbox.y, w = bbox.w - fill_w, h = bbox.h }, color = _.colors.progress_bar_bg } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_wire", bbox = bbox, color = _.colors.progress_bar_border } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = str, bbox = bbox, color = _.colors.text } )
end

function UI.Separator()
	local bbox = {}
	if _.layout.same_line then
		return
	else
		bbox = { x = 0, y = _.layout.prev_y + _.layout.row_h + (_.margin / 2) - (_.separator_thickness / 2), w = 0, h = 0 }
	end

	_.UpdateLayout( bbox )

	table.insert( _.windows[ #_.windows ].command_list, { is_separator = true, type = "rect_fill", bbox = bbox, color = _.colors.separator } )
end

function UI.ImageButton( img_filename, width, height, text )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. img_filename .. _.widget_counter )
	local ib_idx = _.FindId( _.image_buttons, my_id )

	if ib_idx == nil then
		local tex = lovr.graphics.newTexture( img_filename )
		local ib = {
			id = my_id,
			img_filename = img_filename,
			texture = tex,
			w = width or tex:getWidth(),
			h = height or tex:getHeight(),
			ttl = _.image_buttons_default_ttl
		}
		table.insert( _.image_buttons, ib )
		ib_idx = #_.image_buttons
	end

	local ib = _.image_buttons[ ib_idx ]
	ib.ttl = _.image_buttons_default_ttl

	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = ib.w, h = ib.h }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = ib.w, h = ib.h }
	end


	local text_w, text_h

	if text then
		text_w = _.font.handle:getWidth( text )
		text_h = _.font.handle:getHeight()

		if text_h > bbox.h then
			bbox.h = text_h
		end
		bbox.w = bbox.w + (2 * _.margin) + text_w
	end

	_.UpdateLayout( bbox )

	local result = false

	if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
		if _.PointInRect( _.last_off_x, _.last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == _.hovered_window_id then
			_.hotID = my_id
			table.insert( _.windows[ #_.windows ].command_list, { type = "rect_wire", bbox = bbox, color = _.colors.image_button_border_highlight } )
			if _.input.trigger == _.e_trigger.pressed then
				_.activeID = my_id
			end
			if _.input.trigger == _.e_trigger.released and _.hotID == _.activeID then
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
				result = true
			end
		end
	end

	if text then
		table.insert( _.windows[ #_.windows ].command_list,
			{ type = "image", bbox = { x = bbox.x, y = bbox.y + ((bbox.h - ib.h) / 2), w = ib.w, h = ib.h }, texture = ib.texture, color = { 1, 1, 1 } } )
		table.insert( _.windows[ #_.windows ].command_list,
			{ type = "text", text = text, bbox = { x = bbox.x + ib.w, y = bbox.y, w = text_w + (2 * _.margin), h = bbox.h }, color = _.colors.text } )
	else
		table.insert( _.windows[ #_.windows ].command_list, { type = "image", bbox = bbox, texture = ib.texture, color = { 1, 1, 1 } } )
	end

	return result
end

function UI.WhiteBoard( name, width, height )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. name .. _.widget_counter )
	local wb_idx = _.FindId( _.whiteboards, my_id )

	if wb_idx == nil then
		local tex = lovr.graphics.newTexture( width, height, { mipmaps = false } )
		local wb = { id = my_id, texture = tex, w = width or tex:getWidth(), h = height or tex:getHeight(), ttl = _.whiteboards_default_ttl }
		table.insert( _.whiteboards, wb )
		wb_idx = #_.whiteboards
	end

	local wb = _.whiteboards[ wb_idx ]
	wb.ttl = _.whiteboards_default_ttl

	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = wb.w, h = wb.h }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = wb.w, h = wb.h }
	end

	_.UpdateLayout( bbox )

	local clicked = false
	local down = false
	local released = false
	local hovered = false

	if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
		if _.PointInRect( _.last_off_x, _.last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == _.hovered_window_id then
			_.hotID = my_id
			hovered = true
			if _.input.trigger == _.e_trigger.pressed then
				_.activeID = my_id
				clicked = true
			end
			if _.input.trigger == _.e_trigger.down and _.activeID == my_id then
				down = true
			end
			if _.input.trigger == _.e_trigger.released and _.hotID == _.activeID then
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
				released = true
			end
		end
	end

	table.insert( _.windows[ #_.windows ].command_list, { type = "image", bbox = bbox, texture = wb.texture, color = { 1, 1, 1 } } )

	local p = lovr.graphics.newPass( wb.texture )
	p:setDepthTest( nil )
	p:setProjection( 1, mat4():orthographic( p:getDimensions() ) )
	table.insert( _.passes, p )
	return p, clicked, down, released, hovered, _.last_off_x - bbox.x, _.last_off_y - bbox.y
end

function UI.Dummy( width, height )
	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = width, h = height }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = width, h = height }
	end

	_.UpdateLayout( bbox )
end

function UI.TabBar( name, tabs, idx )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. name .. _.widget_counter )

	local text_h = _.font.handle:getHeight()
	local bbox = {}

	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = 0, h = (2 * _.margin) + text_h }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = 0, h = (2 * _.margin) + text_h }
	end

	local result = false, idx
	local total_w = 0
	local col = _.colors.tab_bar_bg
	local x_off = bbox.x

	for i, v in ipairs( tabs ) do
		local text_w = _.font.handle:getWidth( v )
		local tab_w = text_w + (2 * _.margin)
		bbox.w = bbox.w + tab_w

		if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
			if _.PointInRect( _.last_off_x, _.last_off_y, x_off, bbox.y, tab_w, bbox.h ) and cur_window.id == _.hovered_window_id then
				_.hotID = my_id
				col = _.colors.tab_bar_hover
				if _.input.trigger == _.e_trigger.pressed then
					_.activeID = my_id
				end
				if _.input.trigger == _.e_trigger.released and _.hotID == _.activeID then
					lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
					idx = i
					result = true
				end
			else
				col = _.colors.tab_bar_bg
			end
		end

		local tab_rect = { x = x_off, y = bbox.y, w = tab_w, h = bbox.h }
		table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = tab_rect, color = col } )
		table.insert( _.windows[ #_.windows ].command_list, { type = "rect_wire", bbox = tab_rect, color = _.colors.tab_bar_border } )
		table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = v, bbox = tab_rect, color = _.colors.text } )

		if idx == i then
			table.insert( _.windows[ #_.windows ].command_list,
				{ type = "rect_fill", bbox = { x = tab_rect.x + 2, y = tab_rect.y + tab_rect.h - 6, w = tab_rect.w - 4, h = 5 }, color = _.colors.tab_bar_highlight } )
		end
		x_off = x_off + tab_w
	end

	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_wire", bbox = bbox, color = _.colors.tab_bar_border } )
	_.UpdateLayout( bbox )

	return result, idx
end

function UI.Button( text, width, height )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. text .. _.widget_counter )

	local text_w = _.font.handle:getWidth( text )
	local text_h = _.font.handle:getHeight()
	local num_lines = _.GetLineCount( text )

	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = (2 * _.margin) + text_w, h = (2 * _.margin) + (num_lines * text_h) }
	elseif _.layout.same_column then
		bbox = { x = _.layout.prev_x, y = _.layout.prev_y + _.layout.prev_h + _.margin, w = (2 * _.margin) + text_w, h = (2 * _.margin) + (num_lines * text_h) }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = (2 * _.margin) + text_w, h = (2 * _.margin) + (num_lines * text_h) }
	end

	if width and type( width ) == "number" and width > bbox.w then
		bbox.w = width
	end
	if height and type( height ) == "number" and height > bbox.h then
		bbox.h = height
	end

	_.UpdateLayout( bbox )

	local result = false
	local col = _.colors.button_bg
	if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
		if _.PointInRect( _.last_off_x, _.last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == _.hovered_window_id then
			_.hotID = my_id
			col = _.colors.button_bg_hover
			if _.input.trigger == _.e_trigger.pressed then
				_.activeID = my_id
			end
			if _.input.trigger == _.e_trigger.released and _.hotID == _.activeID then
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
				result = true
			end
		end
	end

	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = bbox, color = col } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_wire", bbox = bbox, color = _.colors.button_border } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = text, bbox = bbox, color = _.colors.text } )

	return result
end

function UI.TextBox( name, num_visible_chars, buffer )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. name .. _.widget_counter )
	local tb_idx = _.FindId( _.textbox_state, my_id )

	if tb_idx == nil then
		local str_len = _.utf8.len( buffer, 1, -1 )
		local scrl = 1
		local tb = { id = my_id, text = buffer, scroll = scrl, cursor = 0, num_visible_chars = num_visible_chars }
		table.insert( _.textbox_state, tb )
		tb_idx = #_.textbox_state
	end

	local text_h = _.font.handle:getHeight()
	local char_w = _.font.handle:getWidth( "W" )
	local label_w = _.font.handle:getWidth( name )

	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = (4 * _.margin) + (num_visible_chars * char_w) + label_w, h = (2 * _.margin) + text_h }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = (4 * _.margin) + (num_visible_chars * char_w) + label_w, h = (2 * _.margin) + text_h }
	end

	_.UpdateLayout( bbox )

	local col1 = _.colors.textbox_bg
	local col2 = _.colors.textbox_border
	local text_rect = { x = bbox.x, y = bbox.y, w = bbox.w - _.margin - label_w, h = bbox.h }
	local label_rect = { x = text_rect.x + text_rect.w + _.margin, y = bbox.y, w = label_w, h = bbox.h }
	local got_focus = false

	if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
		if _.PointInRect( _.last_off_x, _.last_off_y, text_rect.x, text_rect.y, text_rect.w, text_rect.h ) and cur_window.id == _.hovered_window_id then
			_.hotID = my_id
			col1 = _.colors.textbox_bg_hover
			if _.input.trigger == _.e_trigger.pressed then
				_.activeID = my_id
			end
			if _.input.trigger == _.e_trigger.released and _.hotID == _.activeID then
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
				osk.visible = true
				_.focused_textbox = _.textbox_state[ tb_idx ]
				local str_len = _.utf8.len( _.focused_textbox.text, 1, -1 )
				_.focused_textbox.cursor = str_len

				_.focused_textbox.scroll = 1
				_.focused_textbox.cursor = 0

				got_focus = true
			end
		end
	end

	local str = ""
	if #_.textbox_state[ tb_idx ].text > 0 then
		local str_len = _.utf8.len( _.textbox_state[ tb_idx ].text, 1, -1 )
		if str_len ~= #_.textbox_state[ tb_idx ].text then
			if str_len >= num_visible_chars then
				str = _.utf8.sub( _.textbox_state[ tb_idx ].text, 1, num_visible_chars )
			else
				str = _.utf8.sub( _.textbox_state[ tb_idx ].text, 1, str_len )
			end
		else
			str = _.textbox_state[ tb_idx ].text:sub( 1, num_visible_chars )
		end
	end

	local buffer_changed = false

	if _.focused_textbox and _.focused_textbox.id == my_id then
		col2 = _.colors.textbox_border_focused
		if osk.last_key then
			if osk.last_key == "left" then
				_.focused_textbox.cursor = _.focused_textbox.cursor - 1
				if _.focused_textbox.cursor < _.focused_textbox.scroll - 1 then
					_.focused_textbox.scroll = _.focused_textbox.scroll - 1
					if _.focused_textbox.scroll < 1 then _.focused_textbox.scroll = 1 end
				end
				if _.focused_textbox.cursor < 0 then _.focused_textbox.cursor = 0 end
			elseif osk.last_key == "right" then
				_.focused_textbox.cursor = _.focused_textbox.cursor + 1
				if _.focused_textbox.cursor > _.focused_textbox.num_visible_chars + _.focused_textbox.scroll - 1 then
					_.focused_textbox.scroll = _.focused_textbox.scroll + 1
					if _.focused_textbox.scroll > _.utf8.len( _.focused_textbox.text, 1, -1 ) - _.focused_textbox.num_visible_chars then
						_.focused_textbox.scroll = _.utf8.len( _.focused_textbox.text, 1, -1 ) - _.focused_textbox.num_visible_chars + 1
					end
				end
				if _.focused_textbox.cursor > _.utf8.len( _.focused_textbox.text, 1, -1 ) then _.focused_textbox.cursor = _.utf8.len( _.focused_textbox.text, 1, -1 ) end
			elseif osk.last_key == "backspace" then
				if _.focused_textbox.cursor > 0 then
					buffer_changed = true
					local s1 = _.utf8.sub( _.focused_textbox.text, 1, _.focused_textbox.cursor - 1 )
					local s2 = _.utf8.sub( _.focused_textbox.text, _.focused_textbox.cursor + 1, -1 )
					_.focused_textbox.text = s1 .. s2
					_.focused_textbox.cursor = _.focused_textbox.cursor - 1
					if _.focused_textbox.scroll > _.utf8.len( _.focused_textbox.text, 1 ) - _.focused_textbox.num_visible_chars + 1 then
						_.focused_textbox.scroll = _.focused_textbox.scroll - 1
						if _.focused_textbox.scroll < 1 then _.focused_textbox.scroll = 1 end
					end
				end
			elseif osk.last_key == "return" then
				return got_focus, buffer_changed, my_id, _.textbox_state[ tb_idx ].text
			else
				buffer_changed = true
				local s1 = _.utf8.sub( _.focused_textbox.text, 1, _.focused_textbox.cursor )
				local s2 = _.utf8.sub( _.focused_textbox.text, _.focused_textbox.cursor + 1, -1 )

				_.focused_textbox.text = s1 .. osk.last_key .. s2
				_.focused_textbox.cursor = _.focused_textbox.cursor + 1
				if _.focused_textbox.cursor > _.focused_textbox.num_visible_chars then
					_.focused_textbox.scroll = _.focused_textbox.scroll + 1
				end
			end
		end

		if #_.focused_textbox.text > 0 then
			local str_len = _.utf8.len( _.focused_textbox.text, 1, -1 )
			if str_len ~= #_.focused_textbox.text then
				if str_len >= num_visible_chars then
					str = _.utf8.sub( _.focused_textbox.text, _.focused_textbox.scroll, _.focused_textbox.scroll + num_visible_chars - 1 )
				else
					str = _.utf8.sub( _.focused_textbox.text, 1, str_len )
				end
			else
				str = _.focused_textbox.text:sub( _.focused_textbox.scroll, _.focused_textbox.scroll + num_visible_chars - 1 )
			end
		end
	end

	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = text_rect, color = col1 } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_wire", bbox = text_rect, color = col2 } )
	table.insert( _.windows[ #_.windows ].command_list, {
		type = "text",
		text = str,
		bbox = {
			x = text_rect.x + _.margin,
			y = text_rect.y,
			w = (_.utf8.len( str, 1 ) * char_w) + _.margin,
			h = text_rect.h
		},
		color = _.colors.text
	} )
	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = name, bbox = label_rect, color = _.colors.text } )

	-- _.caret
	if _.focused_textbox and _.focused_textbox.id == my_id and _.caret.counter % _.caret.blink_rate > (_.caret.blink_rate / 2) then
		table.insert( _.windows[ #_.windows ].command_list,
			{
				type = "rect_fill",
				bbox = {
					x = text_rect.x + ((_.textbox_state[ tb_idx ].cursor - _.textbox_state[ tb_idx ].scroll + 1) * char_w) + _.margin + 8,
					y = text_rect.y + _.margin,
					w = 2,
					h = text_h
				},
				color = _.colors.text
			} )
	end

	return got_focus, buffer_changed, my_id, _.textbox_state[ tb_idx ].text
end

function UI.ListBox( name, num_visible_rows, num_visible_chars, collection, selected )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. name .. _.widget_counter )
	local lst_idx = _.FindId( _.listbox_state, my_id )

	if lst_idx == nil then
		local selected_idx = 1
		if (type( selected ) == "number") then
			selected_idx = selected
		elseif (type( selected ) == "string") then
			for i = 1, #collection do
				if selected == collection[ i ] then
					selected_idx = i
					break
				end
			end
		end
		local l = { id = my_id, scroll = 1, selected_idx = selected_idx }
		table.insert( _.listbox_state, l )
		lst_idx = #_.listbox_state
	end

	local char_w = _.font.handle:getWidth( "W" )
	local text_h = _.font.handle:getHeight()

	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = (2 * _.margin) + (num_visible_chars * char_w), h = (num_visible_rows * text_h) }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = (2 * _.margin) + (num_visible_chars * char_w), h = (num_visible_rows * text_h) }
	end

	_.UpdateLayout( bbox )

	local highlight_idx = nil
	local result = false

	local scrollmax = #collection - num_visible_rows + 1
	if #collection < num_visible_rows then scrollmax = 1 end
	if _.listbox_state[ lst_idx ].scroll > scrollmax then _.listbox_state[ lst_idx ].scroll = scrollmax end

	if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
		if _.PointInRect( _.last_off_x, _.last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == _.hovered_window_id then
			_.hotID = my_id
			highlight_idx = math.floor( (_.last_off_y - bbox.y) / (text_h) ) + 1
			highlight_idx = _.Clamp( highlight_idx, 1, #collection )

			-- Select
			if _.input.trigger == _.e_trigger.pressed then
				_.activeID = my_id
			end
			if _.input.trigger == _.e_trigger.released and _.hotID == _.activeID then
				_.listbox_state[ lst_idx ].selected_idx = highlight_idx + _.listbox_state[ lst_idx ].scroll - 1
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
				result = true
			end

			-- Scroll
			local thumb_x, thumb_y = lovr.headset.getAxis( _.dominant_hand, "thumbstick" )
			if thumb_y > 0.7 then
				_.listbox_state[ lst_idx ].scroll = _.listbox_state[ lst_idx ].scroll - 1
				_.listbox_state[ lst_idx ].scroll = _.Clamp( _.listbox_state[ lst_idx ].scroll, 1, scrollmax )
			end

			if thumb_y < -0.7 then
				_.listbox_state[ lst_idx ].scroll = _.listbox_state[ lst_idx ].scroll + 1
				_.listbox_state[ lst_idx ].scroll = _.Clamp( _.listbox_state[ lst_idx ].scroll, 1, scrollmax )
			end
		end
	end

	_.listbox_state[ lst_idx ].selected_idx = _.Clamp( _.listbox_state[ lst_idx ].selected_idx, 0, #collection )
	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = bbox, color = _.colors.list_bg } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_wire", bbox = bbox, color = _.colors.list_border } )

	-- Draw selected rect
	local lst_scroll = _.listbox_state[ lst_idx ].scroll
	local lst_selected_idx = _.listbox_state[ lst_idx ].selected_idx

	if lst_selected_idx >= lst_scroll and lst_selected_idx <= lst_scroll + num_visible_rows then
		local selected_rect = { x = bbox.x, y = bbox.y + (lst_selected_idx - lst_scroll) * text_h, w = bbox.w, h = text_h }
		table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = selected_rect, color = _.colors.list_selected } )
	end

	-- Draw highlight when hovered
	if highlight_idx ~= nil then
		local highlight_rect = { x = bbox.x, y = bbox.y + ((highlight_idx - 1) * text_h), w = bbox.w, h = text_h }
		table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = highlight_rect, color = _.colors.list_highlight } )
	end

	local y_offset = bbox.y
	local last = lst_scroll + num_visible_rows - 1
	if #collection < num_visible_rows then
		last = #collection
	end

	for i = lst_scroll, last do
		local str = collection[ i ]
		local num_chars = _.utf8.len( str )

		if num_chars > num_visible_chars then
			if num_chars ~= #str then
				local count = _.utf8.offset( str, num_visible_chars, 1 )
				str = _.utf8.sub( str, 1, num_visible_chars )
			else
				str = str:sub( 1, num_visible_chars )
			end
		end

		local item_w = _.font.handle:getWidth( str )
		table.insert( _.windows[ #_.windows ].command_list,
			{ type = "text", text = str, bbox = { x = bbox.x, y = y_offset, w = item_w + _.margin, h = text_h }, color = _.colors.text } )
		y_offset = y_offset + text_h
	end

	return result, _.listbox_state[ lst_idx ].selected_idx
end

function UI.SliderInt( text, v, v_min, v_max, width )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. text .. _.widget_counter )

	local text_w = _.font.handle:getWidth( text )
	local text_h = _.font.handle:getHeight()
	local char_w = _.font.handle:getWidth( "W" )

	local slider_w = 10 * char_w
	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = slider_w + _.margin + text_w, h = (2 * _.margin) + text_h }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = slider_w + _.margin + text_w, h = (2 * _.margin) + text_h }
	end

	if width and type( width ) == "number" and width > bbox.w then
		bbox.w = width
		slider_w = width - _.margin - text_w
	end

	-- Silently replace with a textbox
	if _.focused_slider == my_id then
		bbox.w = -_.margin
		_.UpdateLayout( bbox )
		UI.SameLine()
		local gf, bc, id, txt
		gf, bc, id, txt = UI.TextBox( text, (slider_w - (3 * _.margin)) / char_w, tostring( v ) )

		if bc then
			if tonumber( txt ) then
				v = tonumber( txt )
			end
			if osk.last_key == "return" then
				_.focused_slider = nil
				_.focused_textbox = nil
			end
			return true, v
		else
			return false, v
		end
	else -- Remove redundant state. Might not be called ever again
		local tb_idx = _.FindId( _.textbox_state, my_id )
		if tb_idx then
			table.remove( _.textbox_state, tb_idx )
		end
	end

	_.UpdateLayout( bbox )

	local thumb_w = text_h
	local col = _.colors.slider_bg
	local result = false

	if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
		if _.PointInRect( _.last_off_x, _.last_off_y, bbox.x, bbox.y, slider_w, bbox.h ) and cur_window.id == _.hovered_window_id then
			_.hotID = my_id
			col = _.colors.slider_bg_hover

			if _.input.trigger == _.e_trigger.pressed then
				_.activeID = my_id
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
			end
		end
	end

	if not lovr.headset.isDown( _.dominant_hand, "grip" ) then
		if _.input.trigger == _.e_trigger.down and _.activeID == my_id then
			v = _.MapRange( bbox.x + 2, bbox.x + slider_w - 2, v_min, v_max, _.last_off_x )
		end

		if _.input.trigger == _.e_trigger.released and _.activeID == my_id then
			result = true
		end

		v = _.Clamp( math.ceil( v ), v_min, v_max )
		-- stupid way to turn -0 to 0 ???
		if v == 0 then v = 0 end
	else
		if _.input.trigger == _.e_trigger.pressed and _.activeID == my_id then
			_.focused_slider = my_id
		end
	end

	local value_text_w = _.font.handle:getWidth( v )
	local text_label_rect = { x = bbox.x + slider_w + _.margin, y = bbox.y, w = text_w, h = bbox.h }
	local text_value_rect = { x = bbox.x, y = bbox.y, w = slider_w, h = bbox.h }
	local slider_rect = { x = bbox.x, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = slider_w, h = text_h }
	local thumb_pos = _.MapRange( v_min, v_max, bbox.x, bbox.x + slider_w - thumb_w, v )
	local thumb_rect = { x = thumb_pos, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = thumb_w, h = thumb_w }

	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = slider_rect, color = col } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = thumb_rect, color = _.colors.slider_thumb } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = text, bbox = text_label_rect, color = _.colors.text } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = v, bbox = text_value_rect, color = _.colors.text } )
	return result, v
end

function UI.SliderFloat( text, v, v_min, v_max, width, num_decimals )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. text .. _.widget_counter )

	local text_w = _.font.handle:getWidth( text )
	local text_h = _.font.handle:getHeight()
	local char_w = _.font.handle:getWidth( "W" )

	local slider_w = 10 * char_w
	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = slider_w + _.margin + text_w, h = (2 * _.margin) + text_h }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = slider_w + _.margin + text_w, h = (2 * _.margin) + text_h }
	end

	if width and type( width ) == "number" and width > bbox.w then
		bbox.w = width
		slider_w = width - _.margin - text_w
	end

	-- Silently replace with a textbox
	if _.focused_slider == my_id then
		bbox.w = -_.margin
		_.UpdateLayout( bbox )
		UI.SameLine()
		local gf, bc, id, txt
		num_decimals = num_decimals or 2
		local str_fmt = "%." .. num_decimals .. "f"
		gf, bc, id, txt = UI.TextBox( text, (slider_w - (3 * _.margin)) / char_w, string.format( str_fmt, tostring( v ) ) )

		if bc then
			if tonumber( txt ) then
				v = tonumber( txt )
			end
			if osk.last_key == "return" then
				_.focused_slider = nil
				_.focused_textbox = nil
			end
			return true, v
		else
			return false, v
		end
	else -- Remove redundant state. Might not be called ever again
		local tb_idx = _.FindId( _.textbox_state, my_id )
		if tb_idx then
			table.remove( _.textbox_state, tb_idx )
		end
	end

	_.UpdateLayout( bbox )

	local thumb_w = text_h
	local col = _.colors.slider_bg
	local result = false

	if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
		if _.PointInRect( _.last_off_x, _.last_off_y, bbox.x, bbox.y, slider_w, bbox.h ) and cur_window.id == _.hovered_window_id then
			_.hotID = my_id
			col = _.colors.slider_bg_hover

			if _.input.trigger == _.e_trigger.pressed then
				_.activeID = my_id
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
			end
		end
	end

	if not lovr.headset.isDown( _.dominant_hand, "grip" ) then
		if _.input.trigger == _.e_trigger.down and _.activeID == my_id then
			v = _.MapRange( bbox.x + 2, bbox.x + slider_w - 2, v_min, v_max, _.last_off_x )
		end

		if _.input.trigger == _.e_trigger.released and _.activeID == my_id then
			result = true
		end

		v = _.Clamp( v, v_min, v_max )
	else
		if _.input.trigger == _.e_trigger.pressed and _.activeID == my_id then
			_.focused_slider = my_id
		end
	end

	local value_text_w = _.font.handle:getWidth( v )
	local text_label_rect = { x = bbox.x + slider_w + _.margin, y = bbox.y, w = text_w, h = bbox.h }
	local text_value_rect = { x = bbox.x, y = bbox.y, w = slider_w, h = bbox.h }
	local slider_rect = { x = bbox.x, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = slider_w, h = text_h }
	local thumb_pos = _.MapRange( v_min, v_max, bbox.x, bbox.x + slider_w - thumb_w, v )
	local thumb_rect = { x = thumb_pos, y = bbox.y + (bbox.h / 2) - (text_h / 2), w = thumb_w, h = thumb_w }
	num_decimals = num_decimals or 2
	local str_fmt = "%." .. num_decimals .. "f"

	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = slider_rect, color = col } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_fill", bbox = thumb_rect, color = _.colors.slider_thumb } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = text, bbox = text_label_rect, color = _.colors.text } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = string.format( str_fmt, v ), bbox = text_value_rect, color = _.colors.text } )
	return result, v
end

function UI.Label( text, compact )
	local text_w = _.font.handle:getWidth( text )
	local text_h = _.font.handle:getHeight()
	local num_lines = _.GetLineCount( text )

	local mrg = (2 * _.margin)
	if compact then
		mrg = 0
	end

	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = text_w, h = mrg + (num_lines * text_h) }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = text_w, h = mrg + (num_lines * text_h) }
	end

	_.UpdateLayout( bbox )

	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = text, bbox = bbox, color = _.colors.text } )
end

function UI.CheckBox( text, checked )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. text .. _.widget_counter )

	local char_w = _.font.handle:getWidth( "W" )
	local text_w = _.font.handle:getWidth( text )
	local text_h = _.font.handle:getHeight()

	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = text_h + _.margin + text_w, h = (2 * _.margin) + text_h }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = text_h + _.margin + text_w, h = (2 * _.margin) + text_h }
	end

	_.UpdateLayout( bbox )

	local result = false
	local col = _.colors.check_border

	if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
		if _.PointInRect( _.last_off_x, _.last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == _.hovered_window_id then
			_.hotID = my_id
			col = _.colors.check_border_hover

			if _.input.trigger == _.e_trigger.pressed then
				_.activeID = my_id
			end
			if _.input.trigger == _.e_trigger.released and _.hotID == _.activeID then
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
				result = true
			end
		end
	end

	local check_rect = { x = bbox.x, y = bbox.y + _.margin, w = text_h, h = text_h }
	local text_rect = { x = bbox.x + text_h + _.margin, y = bbox.y, w = text_w + _.margin, h = bbox.h }
	table.insert( _.windows[ #_.windows ].command_list, { type = "rect_wire", bbox = check_rect, color = col } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = text, bbox = text_rect, color = _.colors.text } )

	if checked and type( checked ) == "boolean" then
		table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = "✔", bbox = check_rect, color = _.colors.check_mark } )
	end

	return result
end

function UI.RadioButton( text, checked )
	local cur_window = _.windows[ #_.windows ]
	local my_id = _.Hash( cur_window.name .. text .. _.widget_counter )

	local char_w = _.font.handle:getWidth( "W" )
	local text_w = _.font.handle:getWidth( text )
	local text_h = _.font.handle:getHeight()

	local bbox = {}
	if _.layout.same_line then
		bbox = { x = _.layout.prev_x + _.layout.prev_w + _.margin, y = _.layout.prev_y, w = text_h + _.margin + text_w, h = (2 * _.margin) + text_h }
	else
		bbox = { x = _.margin, y = _.layout.prev_y + _.layout.row_h + _.margin, w = text_h + _.margin + text_w, h = (2 * _.margin) + text_h }
	end

	_.UpdateLayout( bbox )

	local result = false
	local col = _.colors.radio_border

	if not _.modal_window or (_.modal_window and _.modal_window == cur_window.id) then
		if _.PointInRect( _.last_off_x, _.last_off_y, bbox.x, bbox.y, bbox.w, bbox.h ) and cur_window.id == _.hovered_window_id then
			_.hotID = my_id
			col = _.colors.radio_border_hover

			if _.input.trigger == _.e_trigger.pressed then
				_.activeID = my_id
			end
			if _.input.trigger == _.e_trigger.released and _.hotID == _.activeID then
				lovr.headset.vibrate( _.dominant_hand, 0.3, 0.1 )
				result = true
			end
		end
	end

	local check_rect = { x = bbox.x, y = bbox.y + _.margin, w = text_h, h = text_h }
	local text_rect = { x = bbox.x + text_h + _.margin, y = bbox.y, w = text_w + _.margin, h = bbox.h }
	table.insert( _.windows[ #_.windows ].command_list, { type = "circle_wire", bbox = check_rect, color = col } )
	table.insert( _.windows[ #_.windows ].command_list, { type = "text", text = text, bbox = text_rect, color = _.colors.text } )

	if checked and type( checked ) == "boolean" then
		table.insert( _.windows[ #_.windows ].command_list, { type = "circle_fill", bbox = check_rect, color = _.colors.radio_mark } )
	end

	return result
end

return UI

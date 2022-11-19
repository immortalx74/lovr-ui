-- NOTE: This demo app is currently completely unstructured, crude and lacks comments.
-- This will be addressed. For the time being it's a testbed during development.

UI = require "ui/ui"
buf = "John"
win2pos = lovr.math.newMat4( 0.1, 1.3, -1.3 )
check1 = true
check2 = false
rb_idx = 1
counter = 0
slider_int_val = 0
slider_float_val = 0
window3_open = false
tab_bar_idx = 1
col_list_idx = 1
progress_value = 0
accumulator = 0
planes = { m = {}, col = {} }
plane_frames = 0
amplitude = 100
frequency = 0.1
zoom = 1

-- Bezier example adapted from http://jsfiddle.net/zj68t53f/20/
function Bezier( t, p0, p1, p2, p3 )
	local cX = 3 * (p1.x - p0.x)
	local bX = 3 * (p2.x - p1.x) - cX
	local aX = p3.x - p0.x - cX - bX

	local cY = 3 * (p1.y - p0.y)
	local bY = 3 * (p2.y - p1.y) - cY
	local aY = p3.y - p0.y - cY - bY

	local x = (aX * math.pow( t, 3 )) + (bX * math.pow( t, 2 )) + (cX * t) + p0.x
	local y = (aY * math.pow( t, 3 )) + (bY * math.pow( t, 2 )) + (cY * t) + p0.y

	return { x = x, y = y }
end

local accuracy = 0.01
local pts = { { x = 30, y = 30 }, { x = 120, y = 100 }, { x = 150, y = 430 }, { x = 400, y = 300 } }
-- local p0 = { x = 30, y = 30 }
-- local p1 = { x = 120, y = 100 }
-- local p2 = { x = 150, y = 430 }
-- local p3 = { x = 400, y = 300 }

local selected_point = nil
local hovered_point = nil

local x, y, a, c1, c2, c3
for i = 1, 10 do
	x = lovr.math.random( 0, 500 )
	y = lovr.math.random( 0, 300 )
	a = lovr.math.random( 0, math.pi * 2 )
	c1 = lovr.math.random()
	c2 = lovr.math.random()
	c3 = lovr.math.random()
	table.insert( planes.m, lovr.math.newMat4( vec3( x, y, 0 ), vec3( 100 ), quat( a, 0, 0, 1 ) ) )
	table.insert( planes.col, { c1, c2, c3 } )
end

-- Override only some colors
custom_theme =
{
	text = { 0.6, 0.5, 0.1 },
	window_bg = { 0.1, 0.1, 0.1 },
	button_bg = { 0.08, 0.08, 0.08 },
	list_bg = { 0.14, 0.14, 0.2 },
}
text1 = "Blah, blah, blah..."
some_list = { "fade", "wrong", "milky", "zinc", "doubt", "proud", "well-to-do",
	"carry", "knife", "ordinary", "yielding", "yawn", "salt", "examine", "historical",
	"group", "certain", "disgusting", "hum", "left", "camera", "grey", "memorize",
	"squalid", "second-hand", "domineering", "puzzled", "cloudy", "arrogant", "flat" }

function lovr.load()
	UI.Init()
	lovr.graphics.setBackgroundColor( 0.4, 0.4, 1 )
	col_list = UI.GetColorNames()

	-- Add an additional language "pack"
	local lower_case =
	{
		"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
		";", "ς", "ε", "ρ", "τ", "υ", "θ", "ι", "ο", "π",
		"α", "σ", "δ", "φ", "γ", "η", "ξ", "κ", "λ", ".",
		"shift", "ζ", "χ", "ψ", "ω", "β", "ν", "μ", ",", "backspace",
		"symbol", "left", "right", " ", " ", " ", "-", "_", "return", "return",
	}

	local upper_case =
	{
		"!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
		";", "ς", "Ε", "Ρ", "Τ", "Υ", "Θ", "Ι", "Ο", "Π",
		"Α", "Σ", "Δ", "Φ", "Γ", "Η", "Ξ", "Κ", "Λ", ":",
		"shift", "Ζ", "Χ", "Ψ", "Ω", "Β", "Ν", "Μ", "?", "backspace",
		"symbol", "left", "right", " ", " ", " ", "<", ">", "return", "return",
	}

	local symbols =
	{
		"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
		"!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
		"+", "=", "[", "]", "{", "}", "\\", "|", "/", "`",
		"shift", "~", ",", ".", "<", ">", ";", ":", "\"", "backspace",
		"symbol", "left", "right", " ", " ", " ", "-", "_", "return", "return",
	}

	UI.AddKeyboardPack( lower_case, upper_case, symbols )
end

function lovr.update( dt )
	UI.InputInfo()
	accumulator = accumulator + (10 * dt)
	progress_value = math.floor( accumulator )
	if progress_value > 70 then
		progress_value = 0
		accumulator = 0
	end

	if plane_frames < 10 then
		plane_frames = plane_frames + 1
	else
		plane_frames = 0
		local x, y, a, c1, c2, c3
		for i = 1, 10 do
			x = lovr.math.random( 0, 500 )
			y = lovr.math.random( 0, 300 )
			a = lovr.math.random( 0, math.pi * 2 )
			c1 = lovr.math.random()
			c2 = lovr.math.random()
			c3 = lovr.math.random()
			planes.m[ i ]:set( vec3( x, y, 0 ), vec3( zoom * 100 ), quat( a, 0, 0, 1 ) )
			planes.col[ i ] = { c1, c2, c3 }
		end
	end
end

function lovr.draw( pass )
	pass:setColor( .1, .1, .12 )
	pass:plane( 0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0 )
	pass:setColor( .2, .2, .2 )
	pass:plane( 0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0, 'line', 50, 50 )

	UI.NewFrame( pass )

	local lh_pose = lovr.math.newMat4( lovr.headset.getPose( "hand/left" ) )
	lh_pose:rotate( -math.pi / 2, 1, 0, 0 )
	UI.Begin( "FirstWindow", mat4( -0.5, 1.4, -1 ) )
	if UI.ImageButton( "ui/lovrlogo.png" ) then print( "imagebutton" ) end
	UI.SameLine()
	UI.Label( "<- An ImageButton" )

	local old_buf = buf
	local got_focus, buffer_changed, textbox_id
	got_focus, buffer_changed, textbox_id, buf = UI.TextBox( "Name", 6, buf ) -- Mutate original string
	if got_focus then
		print( "got focus" )
	end
	if buffer_changed then
		print( "Old text was: " .. "'" .. old_buf .. "'" .. ", new text is: " .. "'" .. buf .. "'" )
		-- Do text validation here. If it fails your rules (invalid character, text length too long. etc.) then you can set the text to a 'valid' value as follows:
		-- UI.SetTextBoxText( textbox_id, "My new text" )
	end
	UI.TextBox( "Profession", 20, "" )
	if UI.Button( "Test", 0, 0 ) then
		print( buf )
	end
	UI.SameLine()
	UI.Button( "SameLine()" )
	if UI.Button( "Times clicked: " .. counter ) then
		counter = counter + 1
	end
	UI.SameLine()
	if UI.CheckBox( "Really?", check1 ) then
		check1 = not check1
	end
	UI.Label( "Hello world in Greek: Γεια σου κόσμε!" )
	local s1, s2
	s1, slider_int_val = UI.SliderInt( "SliderInt", slider_int_val, -100, 100, 400 )
	s2, slider_float_val = UI.SliderFloat( "SliderFloat", slider_float_val, -100, 100, 400, 3 )
	UI.Label( "Some list of things:" )
	local list_clicked, list_selected_idx = UI.ListBox( "Somelistbox", 15, 20, some_list )
	if list_clicked then
		print( list_selected_idx )
	end
	UI.SameLine()
	if UI.Button( "Delete" ) then table.remove( some_list ) end
	if UI.RadioButton( "Radio1", rb_idx == 1 ) then
		rb_idx = 1
	end
	if UI.RadioButton( "Radio2", rb_idx == 2 ) then
		rb_idx = 2
	end
	if UI.RadioButton( "Radio3", rb_idx == 3 ) then
		rb_idx = 3
	end
	UI.End( pass )

	UI.Begin( "SecondWindow", win2pos )
	UI.TextBox( "Location", 20, "" )
	if UI.Button( "AhOh" ) then print( UI.GetWindowSize( "FirstWindow" ) ) end

	-- whiteboard 1
	UI.Label( "Click & drag R/L to zoom in/out:" )
	local ps, clicked, down, released, hovered, lx, ly = UI.WhiteBoard( "WhiteBoard1", 500, 300 )
	ps:setColor( 0, 0, 0 )
	ps:fill()

	if down then
		zoom = (lx * 0.01)
	end

	for i = 1, 10 do
		ps:setColor( planes.col[ i ] )
		ps:plane( planes.m[ i ] )
	end

	-- whiteboard 2
	UI.Label( "Use the sliders or \nclick & drag on waveform:" )
	local ps, clicked, down, released, hovered, lx, ly = UI.WhiteBoard( "WhiteBoard2", 500, 300 )
	if down then
		-- amplitude = -(ly / 2)
		amplitude = (150 * ly) / 300
		frequency = (0.2 * lx) / 500
	end
	if hovered then
		ps:setColor( 0.1, 0, 0.2 )
	else
		ps:setColor( 0, 0, 0 )
	end
	ps:fill()
	ps:setColor( 1, 1, 1 )

	local xx = 0
	local yy = 0
	local y = 150

	for i = 1, 500 do
		yy = y + (amplitude * math.sin( frequency * xx ))
		ps:points( xx, yy, 0 )
		xx = xx + 1
	end

	local a_released, f_released
	a_released, amplitude = UI.SliderFloat( "Amplitude", amplitude, 0, 150, 500 )
	f_released, frequency = UI.SliderFloat( "Frequency", frequency, 0, 0.2, 500 )

	-- whiteboard 3
	local ps, clicked, down, released, hovered, lx, ly = UI.WhiteBoard( "WhiteBoard3", 500, 500 )
	if hovered then
		for i = 1, 4 do
			if lx > pts[ i ].x - 10 and lx < pts[ i ].x + 10 and ly > pts[ i ].y - 10 and ly < pts[ i ].y + 10 then
				hovered_point = i
				if clicked then
					selected_point = i
					hovered_point = nil
				end
				break
			else
				hovered_point = nil
			end
		end
	end
	if released then
		selected_point = nil
	end
	if selected_point then
		if lx >= 0 and lx <= 500 then
			pts[ selected_point ].x = lx
		end
		if ly >= 0 and ly <= 500 then
			pts[ selected_point ].y = ly
		end
	end
	ps:setColor( 0, 0, 0 )
	ps:fill()

	ps:setColor( 1, 1, 0 )
	local startx = pts[ 1 ].x
	local starty = pts[ 1 ].y

	for i = 0, 1, accuracy do
		local p = Bezier( i, pts[ 1 ], pts[ 2 ], pts[ 3 ], pts[ 4 ] )
		ps:line( startx, starty, 0, p.x, p.y, 0 )
		startx = p.x
		starty = p.y
	end

	ps:setColor( 0.15, 0.15, 0.15 )
	ps:line( pts[ 1 ].x, pts[ 1 ].y, 0, pts[ 2 ].x, pts[ 2 ].y, 0, pts[ 3 ].x, pts[ 3 ].y, 0, pts[ 4 ].x, pts[ 4 ].y, 0 )

	ps:setColor( 1, 0, 1 )
	ps:plane( pts[ 1 ].x, pts[ 1 ].y, 0, 20 )
	ps:setColor( 0, 1, 1 )
	ps:plane( pts[ 2 ].x, pts[ 2 ].y, 0, 20 )
	ps:plane( pts[ 3 ].x, pts[ 3 ].y, 0, 20 )
	ps:setColor( 1, 0, 1 )
	ps:plane( pts[ 4 ].x, pts[ 4 ].y, 0, 20 )

	if hovered_point then
		ps:setColor( 1, 1, 1 )
		ps:plane( pts[ hovered_point ].x, pts[ hovered_point ].y, 0, 30 )
	end
	if selected_point then
		ps:setColor( 1, 1, 0 )
		ps:plane( pts[ selected_point ].x, pts[ selected_point ].y, 0, 30 )
	end

	local r
	r, pts[ 1 ].x = UI.SliderFloat( "p1.x", pts[ 1 ].x, 0, 500 );
	UI.SameLine();
	r, pts[ 1 ].y = UI.SliderFloat( "p1.y", pts[ 1 ].y, 0, 500 )
	r, pts[ 2 ].x = UI.SliderFloat( "p2.x", pts[ 2 ].x, 0, 500 );
	UI.SameLine();
	r, pts[ 2 ].y = UI.SliderFloat( "p2.y", pts[ 2 ].y, 0, 500 )
	r, pts[ 3 ].x = UI.SliderFloat( "p3.x", pts[ 3 ].x, 0, 500 );
	UI.SameLine();
	r, pts[ 3 ].y = UI.SliderFloat( "p3.y", pts[ 3 ].y, 0, 500 )
	r, pts[ 4 ].x = UI.SliderFloat( "p4.x", pts[ 4 ].x, 0, 500 );
	UI.SameLine();
	r, pts[ 4 ].y = UI.SliderFloat( "p4.y", pts[ 4 ].y, 0, 500 )

	UI.Label( "Energy bill increase:" )
	UI.ProgressBar( progress_value, 400 )
	UI.Button( "Forced height", 0, 200 )
	UI.Button( "Forced width", 400 )

	if UI.CheckBox( "Check Me", check2 ) then
		check2 = not check2
	end

	if UI.Button( "Toggle another window opened/closed\nattached to your left hand" ) then
		window3_open = not window3_open
	end
	UI.End( pass )

	if window3_open then
		UI.Begin( "ThirdWindow", lh_pose )
		UI.ImageButton( "ui/lovrlogo.png", 32, 32 )
		UI.Label( "Operating System: " .. lovr.system.getOS() )
		UI.Label( "User Directory: " .. (lovr.filesystem.getUserDirectory() or 'N/A') )
		UI.Label( "Average Delta: " .. string.format( "%.6f", lovr.timer.getAverageDelta() ) )
		if UI.Button( "Close Me" ) then
			window3_open = false
		end
		UI.End( pass )
	end

	UI.Begin( "TabBar window", mat4( -0.9, 1.4, -1 ) )
	local was_clicked, idx = UI.TabBar( "my tab bar", { "first", "second", "third" }, tab_bar_idx )
	if was_clicked then
		tab_bar_idx = idx
	end
	if tab_bar_idx == 1 then
		UI.Button( "Button on 1st tab" )
		UI.Label( "Label on 1st tab" )
		UI.Label( "LÖVR..." )
	elseif tab_bar_idx == 2 then
		UI.Button( "Button on 2nd tab" )
		UI.Label( "Label on 2nd tab" )
		UI.Label( "is..." )
	elseif tab_bar_idx == 3 then
		UI.Button( "Button on 3rd tab" )
		UI.Label( "Label on 3rd tab" )
		UI.Label( "awesome!" )
	end
	UI.End( pass )

	-- color tweaker test
	UI.Begin( "Color editor window", mat4( 0.5, 1.2, -1.3 ) )
	UI.Label( "Color editor" )
	local button_bg_color = UI.GetColor( "button_bg" )
	local text_color = UI.GetColor( "text" )

	UI.OverrideColor( "text", { 0, 0, 0 } )
	UI.OverrideColor( "button_bg", { 1, 0, 0 } )
	UI.Button( "Override" )
	UI.SameLine()

	UI.OverrideColor( "text", { 0, 0, 0 } )
	UI.OverrideColor( "button_bg", { 0, 1, 0 } )
	UI.Button( "some" )
	UI.SameLine()

	UI.OverrideColor( "text", { 1, 1, 1 } )
	UI.OverrideColor( "button_bg", { 0, 0, 1 } )
	UI.Button( "colors" )

	UI.OverrideColor( "button_bg", button_bg_color )
	UI.OverrideColor( "text", text_color )
	UI.Label( "Set theme:" )
	if UI.Button( "Dark" ) then
		UI.SetColorTheme( "dark" )
	end
	UI.SameLine()
	if UI.Button( "Light" ) then
		UI.SetColorTheme( "light" )
	end
	UI.SameLine()
	if UI.Button( "Custom..." ) then
		UI.SetColorTheme( custom_theme, "dark" )
	end

	local val = UI.GetColor( col_list[ col_list_idx ] )
	if val then
		local rdown, gdown, bdown
		r_released, val[ 1 ] = UI.SliderFloat( "R", val[ 1 ], 0, 1, 600, 3 )
		g_released, val[ 2 ] = UI.SliderFloat( "G", val[ 2 ], 0, 1, 600, 3 )
		b_released, val[ 3 ] = UI.SliderFloat( "B", val[ 3 ], 0, 1, 600, 3 )
		if r_released or g_released or b_released then
			UI.SetColor( col_list[ col_list_idx ], { val[ 1 ], val[ 2 ], val[ 3 ] } )
		end
	end
	if UI.Button( "Print to output" ) then
		local t = {}
		print( "my_colors = {" )
		for i, v in ipairs( col_list ) do
			local val = UI.GetColor( col_list[ i ] )
			t[ i ] = val
			print( col_list[ i ] ..
				" = " .. "{" .. string.format( "%.3f", t[ i ][ 1 ] ) .. ", " .. string.format( "%.3f", t[ i ][ 2 ] ) .. ", " .. string.format( "%.3f", t[ i ][ 3 ] ) .. "}," )
		end
		print( "}" )
	end
	col_list_idx = select( 2, UI.ListBox( "color list", 10, 30, col_list ) )
	UI.End( pass )

	UI.RenderFrame( pass )
	return true
end

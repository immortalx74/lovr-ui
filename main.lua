UI = require "ui/ui"

win2pos = lovr.math.newMat4( 0.1, 1.3, -1.3 )
check1 = true
check2 = false
rb_idx = 1
counter = 0
slider_int_val = 0
slider_float_val = 0
window3_open = false
text1 = "Blah, blah, blah..."
some_list = { "fade", "wrong", "milky", "zinc", "doubt", "proud", "well-to-do",
	"carry", "knife", "ordinary", "yielding", "yawn", "salt", "examine", "historical",
	"group", "certain", "disgusting", "hum", "left", "camera", "grey", "memorize",
	"squalid", "second-hand", "domineering", "puzzled", "cloudy", "arrogant", "flat" }

function lovr.load()
	UI.Init()
	lovr.graphics.setBackgroundColor( 0.4, 0.4, 1 )
end

function lovr.update()
	UI.InputInfo()
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
	UI.TextBox( "Name", 6 )
	UI.TextBox( "Profession", 20 )
	if UI.Button( "Test", 0, 0 ) then
		print( "test" )
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
	slider_int_val = UI.SliderInt( "SliderInt", slider_int_val, -100, 100, 400 )
	slider_float_val = UI.SliderFloat( "SliderFloat", slider_float_val, -100, 100, 400, 3 )
	UI.Label( "Some list of things:" )
	UI.ListBox( "Somelistbox", 15, 20, some_list )
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
	UI.TextBox( "Location", 20 )
	if UI.Button( "AhOh" ) then print( UI.GetWindowSize( "FirstWindow" ) ) end
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
		UI.Label( "Operating System: " .. lovr.system.getOS() )
		UI.Label( "User Directory: " .. lovr.filesystem.getUserDirectory() )
		UI.Label( "Average Delta: " .. string.format( "%.6f", lovr.timer.getAverageDelta() ) )
		if UI.Button( "Close Me" ) then
			window3_open = false
		end
		UI.End( pass )
	end

	UI.RenderFrame( pass )
end

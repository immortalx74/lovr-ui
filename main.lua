UI = require "ui/ui"

-- LOAD
function lovr.load()
	UI.Init()
	lovr.graphics.setBackgroundColor(0.4, 0.4, 1)
end

-- UPDATE
function lovr.update()

end

-- DRAW
function lovr.draw( pass )
	pass:setColor(.1, .1, .12)
	pass:plane(0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0)
	pass:setColor(.2, .2, .2)
	pass:plane(0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0, 'line', 50, 50)

	-- pass:setColor( 1, 0, 0 )
	-- pass:cube( 0, 1.7, -1, .5, lovr.headset.getTime(), 0, 1, 0, 'fill' )
	-- if lovr.headset.wasPressed( "hand/left", "trigger" ) then
	-- 	print( "Hello" )
	-- end

	UI.NewFrame(pass)

	UI.Begin("FirstWindow", 0, 3, -2)
	UI.Button("Test123", 0, 0)
	UI.SameLine()
	UI.Button("SameLine()")
	UI.Button("Hello World!")
	UI.SameLine()
	UI.CheckBox("Really?", true)
	UI.Button("Just Another Button")
	UI.RadioButton("Radio1", 1, true)
	UI.RadioButton("Radio2", 1)
	UI.RadioButton("Radio3", 1)
	UI.End(pass)

	UI.Begin("SecondWindow", 5, 2.7, -3)
	UI.Button("AhOh")
	UI.SameLine()
	UI.Button("Forced height", 0, 200)
	UI.Button("Forced width", 400)
	UI.CheckBox("Check Me")
	UI.End(pass)

	UI.RenderFrame(pass)
end

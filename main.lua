UI = require "ui/ui"

-- LOAD
function lovr.load()
	UI.Init()
	lovr.graphics.setBackgroundColor(0.4, 0.4, 1)
	ch1 = true
	ch2 = false
	rb_idx = 1
	counter = 0
	slider_val = 0
	some_list = { "fade", "wrong", "milky", "zinc", "doubt", "proud", "well-to-do",
		"carry", "knife", "ordinary", "yielding", "yawn", "salt", "examine", "historical",
		"group", "certain", "disgusting", "hum", "left", "camera", "grey", "memorize",
		"squalid", "second-hand", "domineering", "puzzled", "cloudy", "arrogant", "flat" }
	some_list_idx = 2
end

-- UPDATE
function lovr.update()
	UI.RayInfo()
end

-- DRAW
function lovr.draw( pass )
	pass:setColor(.1, .1, .12)
	pass:plane(0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0)
	pass:setColor(.2, .2, .2)
	pass:plane(0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0, 'line', 50, 50)


	UI.NewFrame(pass)

	-- UI.Begin("FirstWindow", 0, 2, -3)
	UI.Begin("FirstWindow", -0.1, 0.7, -0.6)
	if UI.Button("Test", 0, 0) then print("test") end
	UI.SameLine()
	UI.Button("SameLine()")
	if UI.Button("Times clicked: " .. counter) then
		counter = counter + 1
	end
	UI.SameLine()
	if UI.CheckBox("Really?", ch1) then
		ch1 = not ch1
	end
	UI.Label("Hello world in Greek: Γεια σου κόσμε!")
	-- slider_val = UI.Slider("Slider", slider_val, -100, 100, 400+(counter*10))
	slider_val = UI.Slider("Slider", slider_val, -100, 100, 400)
	UI.SameLine()
	UI.Button("Just Another Button")
	-- if UI.Button("Up") then
	-- 	UI.ListUp()
	-- end
	-- if UI.Button("Down") then
	-- 	UI.ListDown()
	-- end
	UI.Label("Some list of things:")
	UI.ListBox("Somelistbox", 15, 20, some_list)
	if UI.RadioButton("Radio1", rb_idx == 1) then
		rb_idx = 1
	end
	if UI.RadioButton("Radio2", rb_idx == 2) then
		rb_idx = 2
	end
	if UI.RadioButton("Radio3", rb_idx == 3) then
		rb_idx = 3
	end
	UI.End(pass)

	-- UI.Begin("SecondWindow", 3, 2.7, -3)
	UI.Begin("SecondWindow", 0.3, 0.5, -0.9)
	UI.Button("AhOh")
	UI.Button("Forced height", 0, 200)
	UI.Button("Forced width", 400)

	if UI.CheckBox("Check Me", ch2) then
		ch2 = not ch2
	end

	UI.End(pass)

	UI.RenderFrame(pass)
end

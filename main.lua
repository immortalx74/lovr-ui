UI = require "ui/ui"

-- LOAD
function lovr.load()
	UI.Init()
	lovr.graphics.setBackgroundColor(0.4, 0.4, 1)
	ch1 = true
	rb_idx = 1
	counter = 0
	slider_val = 0
	fruit_list = {"Apple", "Banana", "Orange", "Avocado", "Pineapple", "Watermelon"}
	fruit_list_idx = 2
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

	UI.Begin("FirstWindow", 0, 2, -3)
	if UI.Button("Test1234567896786868783", 0, 0) then print("test") end
	UI.SameLine()
	UI.Button("SameLine()")
	if UI.Button("Times clicked: " .. counter) then
		counter = counter + 1
	end
	UI.SameLine()
	if UI.CheckBox("Really?", ch1) then
		ch1 = not ch1
	end
	UI.Label("A plain text label")
	slider_val = UI.Slider("Slider", slider_val, -100, 100, 400)
	UI.SameLine()
	UI.Button("Just Another Button")
	UI.ListBox(7, 20, fruit_list, fruit_list_idx)
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

	-- UI.Begin("SecondWindow", 5, 2.7, -3)
	-- UI.Button("AhOh")
	-- UI.Button("Forced height", 0, 200)
	-- UI.Button("Forced width", 400)
	-- UI.CheckBox("Check Me")
	-- UI.End(pass)

	UI.RenderFrame(pass)
end

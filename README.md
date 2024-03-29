## lovr-ui
### An immediate mode VR GUI library for [LÖVR](https://lovr.org/)
( For a retained mode UI library check out [chui](https://github.com/jmiskovic/chui) )
![lovr-ui](https://i.imgur.com/Q5SHm3H.png)
**How to use:**
 - Put the ui folder inside your project and require it: `UI = require "ui/ui"`
 - Initialize the library by calling `UI.Init()` on `lovr.load()`
 - Handle controller input by calling `UI.InputInfo()` on `lovr.update()`
 - Everything inside `NewFrame()`/`RenderFrame()` is your GUI

**Input:**

 - Change the dominant hand by pushing the corresponding trigger button.
 - Scroll in ListBox with the Y-axis of the analog stick.
 - Text entry is done by an on-screen keyboard (appears when a TextBox has focus).
 - If additional keyboard languages are provided, cycling between them is done by holding grip and pressing the trigger on the space key.
 - Enter an exact value in a slider by holding down grip and pressing trigger.
 - Move windows by pointing at them and holding the grip button.
 - Enable/Disable interaction with the GUI by pressing the Left Thumbstick down (user configurable).

**Widgets:**

 - Button
 - ImageButton
 - TextBox
 - ListBox
 - SliderInt
 - SliderFloat
 - Label
 - CheckBox
 - RadioButton
 - TabBar
 - Dummy
 - ProgressBar
 - WhiteBoard
 - Modal window
 - Separator

---
`UI.Button(text, width, height)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|button's text
|`width` _[opt]_|number|button width in pixels
|`height` _[opt]_|number|button height in pixels
 
<span style="color:DeepSkyBlue">Returns:</span> `boolean`, true when clicked.  
NOTE:  if no `width` and/or `height` are provided, the button size will be auto-calculated based on text. Otherwise, it will be set to `width` X `height` (with the text centered) or ignored if that size doesn't fit the text. 

---
`UI.ImageButton(img_filename, width, height, text)`
|Argument|Type|Description
|:---|:---|:---|
|`img_filename`|string|image filename
|`width`|number|image width in pixels
|`height`|number|image height in pixels
|`text` _[opt]_|string|optional text

<span style="color:DeepSkyBlue">Returns:</span> `boolean` , true when clicked.  

---
`UI.WhiteBoard(name, width, height)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|string|whiteboard ID
|`width`|number|width in pixels
|`height`|number|height in pixels

<span style="color:DeepSkyBlue">Returns:</span> `Pass`, `boolean`, `boolean`, `boolean`, `boolean`, `number`, `number`, [1] Pass object, [2] clicked, [3] down, [4] released, [5] hovered, [6] X, [7] Y  
NOTE: General purpose widget for custom drawing/interaction. The returned Pass can be used to do regular LÖVR draw-commands  
like plane, circle, text, etc. X and Y are the local 2D coordinates of the pointer (0,0 is top,left)

---
`UI.TextBox(name, num_visible_chars, buffer)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|string|textbox ID
|`num_visible_chars`|number|number of visible characters
|`buffer`|string|user provided text buffer

<span style="color:DeepSkyBlue">Returns:</span> `boolean`, `boolean`, `number`, `string` , [1] got focus, [2] buffer changed, [3] ID, [4] modified buffer.  
NOTE: When clicked, an on-screen keyboard will pop-up for text entry. Enter closes the keyboard. To modify the original buffer assign the 4th return value back to the original buffer variable. The ID returned can be passed in the helper function `UI.SetTextBoxText` to set the desired text after validation. (example in main.lua) 

---
`UI.ListBox(name, num_visible_rows, num_visible_chars, collection, selected)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|string|listbox ID
|`num_visible_rows`|number|number of visible rows
|`num_visible_chars`|number|number of visible characters on each row
|`collection`|table|table of strings
|`selected` _[opt]_|number or string|selected item index (in case it's a string, selects the 1st occurence of the item that matches the string)

<span style="color:DeepSkyBlue">Returns:</span> `boolean`, `number`, [1] true when clicked, [2] the selected item index  

---
`UI.SliderInt(text, v, v_min, v_max, width)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|slider text
|`v`|number|initial value
|`v_min`|number|minimum value
|`v_max`|number|maximum value
|`width` _[opt]_|number|total width in pixels of the slider, including it's text

<span style="color:DeepSkyBlue">Returns:</span> `boolean`, `number`, [1] true when released, [2] the current value  
NOTE: Use this idiom to assign back to the provided number variable: `slider_released, slider_val = UI.SliderInt("My slider", slider_val, 0, 100)`
If width is provided, it will be taken into account only if it exceeds the width of text, otherwise it will be ignored. 

---
`UI.SliderFloat(text, v, v_min, v_max, width, num_decimals)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|slider text
|`v`|number|initial value
|`v_min`|number|minimum value
|`v_max`|number|maximum value
|`width` _[opt]_|number|total width in pixels of the slider, including it's text
|`num_decimals` _[opt]_|number|number of decimals to display

<span style="color:DeepSkyBlue">Returns:</span> `boolean`, `number`, [1] true when released, [2] the current value  
NOTE: Use this idiom to assign back to the provided number variable: `slider_released, slider_val = UI.SliderFloat("My slider", slider_val, 0, 100)`
If `width` is provided, it will be taken into account only if it exceeds the width of text, otherwise it will be ignored. If no `num_decimals` is provided, it defaults to 2.

---
`UI.Label(text)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|label text
|`compact` _[opt]_|boolean|ignore vertical margins

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  

---
`UI.ProgressBar(progress, width)`
|Argument|Type|Description
|:---|:---|:---|
|`progress`|number|progress percentage
|`width` _[opt]_|number|width in pixels

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Default width is 300 pixels

---
`UI.Separator()`
|Argument|Type|Description
|:---|:---|:---|
|`none`||

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Horizontal Separator

---
`UI.CheckBox(text, checked)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|checkbox text
|`checked`|boolean|state

<span style="color:DeepSkyBlue">Returns:</span> `boolean`, true when clicked  
NOTE: To set the state use this idiom: `if UI.CheckBox("My checkbox", my_state) then my_state = not my_state end`

---
`UI.RadioButton(text, checked)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|radiobutton text
|`checked`|boolean|state

<span style="color:DeepSkyBlue">Returns:</span> `boolean`, true when clicked  
NOTE: To set the state on a group of RadioButtons use this idiom: 
`if UI.RadioButton("Radio1", rb_group_idx == 1) then rb_group_idx = 1 end`
`if UI.RadioButton("Radio2", rb_group_idx == 2) then rb_group_idx = 2 end`
`-- etc...`

---
`UI.TabBar(name, tabs, idx)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|string|TabBar ID
|`tabs`|table|a table of strings
|`idx`|number|initial active tab index

<span style="color:DeepSkyBlue">Returns:</span> `boolean`, `number`, [1] true when clicked, [2] the selected tab index  

---
`UI.Dummy(width, height)`
|Argument|Type|Description
|:---|:---|:---|
|`width`|number|width
|`height`|number|height

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: This is an invisible widget useful only to "push" other widgets' positions or to leave a desired gap.

---
`UI.Begin(name, transform, is_modal)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|string|window ID
|`transform`|Mat4|window transform
|`is_modal` _[opt]_|boolean|is this a modal window

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Starts a new window. Every widget call after this function will belong to this window, until `UI.End(main_pass)` is called. If this is set as a modal window (by passing true to the last argument) it should always call `UI.EndModalWindow` before closing it physically. (see example in main.lua)

---
`UI.End(main_pass)`
|Argument|Type|Description
|:---|:---|:---|
|`main_pass`|Pass|the main Pass object

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Ends the current window. 

---
`UI.SameLine()`
|Argument|Type|Description
|:---|:---|:---|
|`none`||

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Places the next widget beside the last one, instead of bellow

---
`UI.GetWindowSize(name)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|number|window ID

<span style="color:DeepSkyBlue">Returns:</span> `number`, `number`, [1] window width, [2] window height  
NOTE: If no window with this ID was found, return type is `nil`

---
`UI.SetTextBoxText(id, text)`
|Argument|Type|Description
|:---|:---|:---|
|`id`|number|textbox ID
|`text`|string|textbox text

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Helper to set the textbox text after validation.

---
`UI.SetInteractionEnabled(enabled)`
|Argument|Type|Description
|:---|:---|:---|
|`enabled`|boolean|if interaction should be enabled

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Useful if you want to set interaction on/off programmatically, without pressing the toggle button

---

`UI.Init(interaction_toggle_device, interaction_toggle_button, enabled, pointer_rotation)`
|Argument|Type|Description
|:---|:---|:---|
|`interaction_toggle_device` _[opt]_|Device|controller
|`interaction_toggle_button` _[opt]_|DeviceButton|controller button that toggles interaction on/off
|`enabled` _[opt]_|boolean|initial state of interaction
|`pointer_rotation` _[opt]_|number|pointer rotation angle (default value is similar to SteamVR/Oculus).

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Should be called on `lovr.load()`. Defaults are `hand/left`, `thumbstick`, `true`, `math.pi / 3` respectively.

---
`UI.InputInfo(emulated_headset, ray_position, ray_orientation)`
|Argument|Type|Description
|:---|:---|:---|
|`emulated_headset` _[opt]_|boolean|emulated headset
|`ray_position` _[opt]_|Vec3|ray position
|`ray_orientation` _[opt]_|Quat|ray orientation

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Should be called on `lovr.update()`. To operate in standard "VR mode" do not pass any arguments. The optional arguments could be passed to emulate the headset with mouse and keyboard. When only the 1st argument is passed, data is captured from the emulated headset directly. When the render pass has a different transform than the headset, then the 2 last arguments should be passed too.

---
`UI.NewFrame(main_pass)`
|Argument|Type|Description
|:---|:---|:---|
|`main_pass`|Pass|the main Pass object

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Should be called on `lovr.draw()`. Windows and widgets should be called after this function, and a `UI.RenderFrame(main_pass)` finalizes the whole UI.

---
`UI.RenderFrame(main_pass)`
|Argument|Type|Description
|:---|:---|:---|
|`main_pass`|Pass|the main Pass object.

<span style="color:DeepSkyBlue">Returns:</span> `table`, ui passes  
NOTE: During the frame, lovr-ui records its own passes for drawing the various elements but doesn't submit them. Instead, a table of those passes is returned to the user where they can be scheduled to be submitted along with the default pass (See the example near the end of main.lua).

---
`UI.GetColorNames()`
|Argument|Type|Description
|:---|:---|:---|
|`none`||

<span style="color:DeepSkyBlue">Returns:</span> `table`, color names  
NOTE: Helper to get the color keys as a table of strings

---
`UI.GetColor(col_name)`
|Argument|Type|Description
|:---|:---|:---|
|`col_name`|string|color key

<span style="color:DeepSkyBlue">Returns:</span> `table`, color value  
NOTE: Helper to get a color value

---
`UI.SetColor(col_name, color)`
|Argument|Type|Description
|:---|:---|:---|
|`col_name`|string|color key
|`col_name`|string|color value

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Helper to set a color value. Don't call this every frame because it regenerates the keyboard textures. Use `UI.OverrideColor` instead.

---
`UI.OverrideColor(col_name, color)`
|Argument|Type|Description
|:---|:---|:---|
|`col_name`|string|color key
|`col_name`|string|color value

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Helper to override a color value.

---
`UI.SetColorTheme(theme, copy_from)`
|Argument|Type|Description
|:---|:---|:---|
|`theme`|string or table|color key or table with overrided keys
|`copy_from` _[opt]_|string|theme to copy values from

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Sets a theme to one of the built-in ones ("dark", "light") if the passed argument is a string. Also accepts a table of colors. If the passed table doesn't contain all of the keys, the rest of them will be copied from the built-in theme of the `copy_from` argument.

---
`UI.CloseModalWindow()`
|Argument|Type|Description
|:---|:---|:---|
|`none`||

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Closes a modal window

---
`UI.AddKeyboardPack(lower_case, upper_case, symbols)`
|Argument|Type|Description
|:---|:---|:---|
|`lower_case`|table|lower case characters
|`upper_case`|table|upper case characters
|`symbols`|table|symbol characters

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Provides the ability to add a language pack for the on-screen keyboard. The default pack is Latin. Cycling between packs is done by holding the grip button and pressing the trigger on the space key of the on-screen keyboard.

---
`UI.GetScale()`
|Argument|Type|Description
|:---|:---|:---|
|`none`||

<span style="color:DeepSkyBlue">Returns:</span> `number`, ui scale 
NOTE: Helper to get the ui scale

---
`UI.SetScale(scale)`
|Argument|Type|Description
|:---|:---|:---|
|`scale`|number|ui scale

<span style="color:DeepSkyBlue">Returns:</span> `nothing`  
NOTE: Helper to set the ui scale. Don't call this every frame (it causes textures to be regenerated)

---

**General Info:**
`UI.Begin()`/`UI.End()` defines a window. Widget function calls placed inside this block, are then part of this window.
lovr-ui currently uses a row-based auto-layout. That means that there are limits to how widgets are positioned.
Widget sizes are mostly character-width based. This is done for simplicity.
This library borrows concepts from the outstanding [Dear ImGui](https://github.com/ocornut/imgui) library and is inspired by [microui](https://github.com/rxi/microui), trying to be simple and minimal.

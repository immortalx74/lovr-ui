## lovr-ui
### An immediate mode VR GUI library for [LÖVR](https://lovr.org/)
**How to use:**
 - Put the ui folder inside your project and do `UI = require "ui/ui"`
 - Initialize the library by calling `UI.Init()` on `lovr.load()`
 - Handle controller input by calling `UI.InputInfo()` on `lovr.update()`
 - Everything inside `NewFrame()`/`RenderFrame()` is your GUI

**Input:**

 - Change the dominant hand by pushing the corresponding trigger button.
 - Scroll in ListBox with the Y-axis of the analog stick.
 - Text entry is done by an on-screen keyboard (appears when a TextBox has focus)

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

---
`UI.Button(text, width, height)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|button's text
|`width` _[opt]_|number|button width in pixels
|`height` _[opt]_|number|button height in pixels
 
Returns `boolean`, true when clicked.  
NOTE:  if no `width` and/or `height` are provided, the button size will be auto-calculated based on text. Otherwise, it will be set to `width` X `height` (with the text centered) or ignored if that size doesn't fit the text. 

---
`UI.ImageButton(img_filename, width, height)`
|Argument|Type|Description
|:---|:---|:---|
|`img_filename`|string|image filename
|`width`|number|image width in pixels
|`height`|number|image height in pixels

Returns `boolean` , true when clicked.  

---
`UI.TextBox(name, num_chars, buffer)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|string|textbox ID
|`num_chars`|number|number of visible characters
|`buffer`|string|user provided text buffer

Returns `string` , the edited text buffer.  
NOTE: When clicked, an on-screen keyboard will pop-up for text entry. Enter closes the keyboard. To modify the original buffer use this idiom: `buf = UI.TextBox("My textbox", 6, buf)`

---
`UI.ListBox(name, num_rows, max_chars, collection)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|string|listbox ID
|`num_rows`|number|number of visible rows
|`max_chars`|number|maximum number of characters displayed on each row
|`collection`|table|table of strings

Returns `boolean`, `number`, [1] true when clicked, [2] the selected item index  

---
`UI.SliderInt(text, v, v_min, v_max, width)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|slider text
|`v`|number|initial value
|`v_min`|number|minimum value
|`v_max`|number|maximum value
|`width` _[opt]_|number|total width in pixels of the slider, including it's text

Returns `number`, the current value  
NOTE: Use this idiom to assign back to the provided number variable: `slider_val = UI.SliderInt("My slider", slider_val, 0, 100)`
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

Returns `number`, the current value  
NOTE: Use this idiom to assign back to the provided number variable: `slider_val = UI.SliderFloat("My slider", slider_val, 0, 100)`
If `width` is provided, it will be taken into account only if it exceeds the width of text, otherwise it will be ignored. If no `num_decimals` is provided, it defaults to 2.

---
`UI.Label(text)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|label text

Returns nothing  

---
`UI.ProgressBar(progress, width)`
|Argument|Type|Description
|:---|:---|:---|
|`progress`|number|progress percentage
|`width` _[opt]_|number|width in pixels

Returns nothing  
NOTE: Default width is 300 pixels

---
`UI.CheckBox(text, checked)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|checkbox text
|`checked`|boolean|state

Returns `boolean`, true when clicked  
NOTE: To set the state use this idiom: `if UI.CheckBox("My checkbox", my_state) then my_state = not my_state end`

---
`UI.RadioButton(text, checked)`
|Argument|Type|Description
|:---|:---|:---|
|`text`|string|radiobutton text
|`checked`|boolean|state

Returns `boolean`, true when clicked  
NOTE: To set the state on a group of RadioButtons use this idiom: 
`if UI.RadioButton("Radio1", rb_group_idx == 1) then rb_group_idx = 1 end`
`if UI.RadioButton("Radio2", rb_group_idx == 2) then rb_group_idx = 2 end`
`-- etc...`

---
`UI.TabBar(tabs, idx)`
|Argument|Type|Description
|:---|:---|:---|
|`tabs`|table|a table of strings
|`idx`|number|initial active tab index

Returns `boolean`, `number`, [1] true when clicked, [2] the selected tab index  

---
`UI.Dummy(width, height)`
|Argument|Type|Description
|:---|:---|:---|
|`width`|number|width
|`height`|number|height

Returns nothing  
NOTE: This is an invisible widget useful only to "push" other widgets' positions or to leave a desired gap.

---
`UI.Begin(name, transform)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|string|window ID
|`transform`|Mat4|window transform

Returns nothing.  
NOTE: Starts a new window. Every widget call after this function will belong to this window, until `UI.End(main_pass)` is called.

---
`UI.End(main_pass)`
|Argument|Type|Description
|:---|:---|:---|
|`main_pass`|Pass|the main Pass object

Returns nothing.  
NOTE: lovr-ui submits the main pass (along it's own passes) every frame.

---
`UI.SameLine()`
|Argument|Type|Description
|:---|:---|:---|
|`none`||

Returns nothing.  
NOTE: Places the next widget beside the last one, instead of bellow

---
`UI.GetWindowSize(name)`
|Argument|Type|Description
|:---|:---|:---|
|`name`|number|window ID

Returns `number`, `number`, [1] window width, [2] window height  
NOTE: If no window with this ID was found, return type is `nil`

---
`UI.SetInteractionEnabled(enabled)`
|Argument|Type|Description
|:---|:---|:---|
|`enabled`|boolean|if interaction should be enabled

Returns `nothing`  
NOTE: Useful if you want to set interaction on/off programmatically, without pressing the toggle button

---

`UI.Init(interaction_toggle_device, interaction_toggle_button, enabled)`
|Argument|Type|Description
|:---|:---|:---|
|`interaction_toggle_device` _[opt]_|Device|controller
|`interaction_toggle_button` _[opt]_|DeviceButton|controller button that toggles interaction on/off
|`enabled` _[opt]_|boolean|initial state of interaction

Returns nothing.  
NOTE: Should be called on `lovr.load()`. Defaults are `hand/left`, `thumbstick`, `true` respectively.

---
`UI.InputInfo()`
|Argument|Type|Description
|:---|:---|:---|
|`none`||

Returns nothing.  
NOTE: Should be called on `lovr.update()`

---
`UI.NewFrame(main_pass)`
|Argument|Type|Description
|:---|:---|:---|
|`main_pass`|Pass|the main Pass object

Returns nothing.  
NOTE: Should be called on `lovr.draw()`. Windows and widgets should be called after this function, and a `UI.RenderFrame(main_pass)` finalizes the whole UI.

---
`UI.RenderFrame(main_pass)`
|Argument|Type|Description
|:---|:---|:---|
|`main_pass`|Pass|the main Pass object.

Returns nothing.  

---
`UI.GetColorNames()`
|Argument|Type|Description
|:---|:---|:---|
|`none`||

Returns `table`, color names  
NOTE: Helper to get the color keys as a table of strings

---
`UI.GetColor(col_name)`
|Argument|Type|Description
|:---|:---|:---|
|`col_name`|string|color key

Returns `table`, color value  
NOTE: Helper to get a color value

---
`UI.SetColor(col_name, color)`
|Argument|Type|Description
|:---|:---|:---|
|`col_name`|string|color key
|`col_name`|string|color value

Returns `nothing`  
NOTE: Helper to set a color value

---
`UI.SetColorTheme(theme, copy_from)`
|Argument|Type|Description
|:---|:---|:---|
|`theme`|string or table|color key or table with overrided keys
|`copy_from` _[opt]_|string|theme to copy values from

Returns `nothing`  
NOTE: Sets a theme to one of the built-in ones ("dark", "light") if the passed argument is a string. Also accepts a table of colors. If the passed table doesn't contain all of the keys, the rest of them will be copied from the built-in theme of the `copy_from` argument.

---

**General Info:**
`UI.Begin()`/`UI.End()` defines a window. Widget function calls placed inside this block, are then part of this window.
lovr-ui currently uses a row-based auto-layout. That means that there are limits to how widgets are positioned.
Widget sizes are mostly character-width based. This is done for simplicity.
This library borrows concepts from the outstanding [Dear ImGui](https://github.com/ocornut/imgui) library and is inspired by [microui](https://github.com/rxi/microui), trying to be simple and minimal (~1000 lines).

![lovr-ui](https://i.imgur.com/gwrlius.png)
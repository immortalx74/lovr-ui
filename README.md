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
 - Interaction can be enabled/disabled by a user-configurable button (default: Left Thumbstick Press)
 - Windows can be dragged with the grip button, if a mutable mat4 is passed in `UI.Begin()`

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

**General Info:**
`UI.Begin()`/`UI.End()` defines a window. Widget function calls placed inside this block, are then part of this window.
lovr-ui currently uses a row-based auto-layout. That means that there are limits to how widgets are positioned.
Widget sizes are mostly character-width based. This is done for simplicity.
This library borrows concepts from the outstanding [Dear ImGui library](https://github.com/ocornut/imgui)

![lovr-ui](https://i.imgur.com/gwrlius.png)

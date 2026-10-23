extends RefCounted
## Shared charcoal UI: inset inventory slots, crisp borders and custom control states.
const TEXT := Color("f2f1e9")
const MUTED := Color("adb4b8")
const PANEL := Color("191c21f5")
const EDGE := Color("444b54")
const ACCENT := Color("bad3a7")

static func box(color := PANEL, border := EDGE, inset := 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color("00000055")
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = inset
	style.content_margin_right = inset
	style.content_margin_top = inset
	style.content_margin_bottom = inset
	return style

static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 30
	for type in ["Label", "Button", "CheckButton"]:
		theme.set_color("font_color", type, TEXT)
		theme.set_color("font_hover_color", type, Color.WHITE)
		theme.set_color("font_pressed_color", type, TEXT)
		theme.set_color("font_disabled_color", type, Color("7b8389"))
	theme.set_stylebox("panel", "PanelContainer", box())
	theme.set_stylebox("panel", "Panel", box())
	theme.set_stylebox("normal", "Button", box(Color("30363e")))
	theme.set_stylebox("hover", "Button", box(Color("414b54"), ACCENT))
	theme.set_stylebox("pressed", "Button", box(Color("20272b"), ACCENT))
	theme.set_stylebox("disabled", "Button", box(Color("202428"), Color("343b42")))
	theme.set_stylebox("focus", "Button", box(Color.TRANSPARENT, Color("dce7d6"), 0))
	theme.set_constant("h_separation", "Button", 12)
	theme.set_stylebox("background", "ProgressBar", box(Color("0c0f13"), EDGE, 0))
	theme.set_stylebox("fill", "ProgressBar", box(ACCENT, ACCENT, 0))
	var rail := box(Color("0b0e12"), Color("3a424b"), 0)
	rail.content_margin_top = 5
	rail.content_margin_bottom = 5
	theme.set_stylebox("slider", "HSlider", rail)
	theme.set_stylebox("grabber_area", "HSlider", box(Color("5e7561"), Color("5e7561"), 0))
	theme.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT, ACCENT, 0))
	return theme

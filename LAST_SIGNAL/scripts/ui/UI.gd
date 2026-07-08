class_name UI
extends RefCounted
## Small helpers for building styled Control UI in code.

static func label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func _sb(bg: Color, border: Color, width := 2, radius := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func button(text: String, accent: Color, min_size := Vector2(260, 48), font_size := 18) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color("#eaf2ff"))
	b.add_theme_color_override("font_hover_color", Color("#ffffff"))
	b.add_theme_color_override("font_pressed_color", accent)
	b.add_theme_stylebox_override("normal", _sb(Color(1, 1, 1, 0.05), accent))
	b.add_theme_stylebox_override("hover", _sb(Color(accent.r, accent.g, accent.b, 0.22), accent))
	b.add_theme_stylebox_override("pressed", _sb(Color(accent.r, accent.g, accent.b, 0.35), accent))
	b.add_theme_stylebox_override("focus", _sb(Color(1, 1, 1, 0.03), accent))
	b.add_theme_stylebox_override("disabled", _sb(Color(1, 1, 1, 0.02), Color(accent.r, accent.g, accent.b, 0.35)))
	return b

static func panel_style(bg := Color("#0c111b"), border := Color("#243247")) -> StyleBoxFlat:
	return _sb(bg, border, 2, 12)

static func fullrect(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

extends Control

const VIEW_W := 1280.0
const VIEW_H  := 720.0

var _done: bool = false


func _ready() -> void:
	MusicPlayer.set_mode(MusicPlayer.Mode.MENU)
	_build()


func _build() -> void:
	# Dark background
	var bg := ColorRect.new()
	bg.size  = Vector2(VIEW_W, VIEW_H)
	bg.color = Color(0.02, 0.03, 0.06)
	add_child(bg)

	# Stars — static scatter
	var stars_node := Node2D.new()
	add_child(stars_node)
	var star_draw := _StarField.new()
	star_draw.size = Vector2(VIEW_W, VIEW_H)
	stars_node.add_child(star_draw)

	# Content column
	var col := VBoxContainer.new()
	col.size                  = Vector2(760, VIEW_H)
	col.position              = Vector2((VIEW_W - 760) * 0.5, 0)
	col.alignment             = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	col.modulate.a            = 0.0
	add_child(col)

	_add_lbl(col, "✦  LAST COLONY  ✦",          46, Color(1.00, 0.85, 0.15))
	_add_lbl(col, "La colonia sobrevivió.",        20, Color(0.60, 0.90, 0.65))
	_spacer(col, 32)
	_add_lbl(col, "DESARROLLO",                   13, Color(0.45, 0.55, 0.45))
	_add_lbl(col, "Enrique Cordero",               26, Color(0.85, 0.95, 0.85))
	_spacer(col, 20)
	_add_lbl(col, "MOTOR",                        13, Color(0.45, 0.55, 0.45))
	_add_lbl(col, "Godot Engine 4.6",              22, Color(0.70, 0.82, 0.70))
	_spacer(col, 20)
	_add_lbl(col, "MÚSICA PROCEDURAL",            13, Color(0.45, 0.55, 0.45))
	_add_lbl(col, "AudioStreamGenerator — síntesis en tiempo real", 17, Color(0.55, 0.75, 0.85))
	_spacer(col, 36)
	_add_lbl(col, "Gracias por jugar.", 28, Color(0.30, 1.00, 0.42))
	_spacer(col, 40)

	var btn := Button.new()
	btn.text = "VOLVER AL HUB"
	btn.add_theme_font_size_override("font_size", 20)
	btn.custom_minimum_size = Vector2(220, 48)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.pressed.connect(_go_hub)
	col.add_child(btn)

	# Fade in
	var tw := create_tween()
	tw.tween_property(col, "modulate:a", 1.0, 1.2)


func _go_hub() -> void:
	if _done:
		return
	_done = true
	StageManager.selected_mission_id = ""
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_go_hub()


func _add_lbl(parent: Control, text: String, sz: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)


func _spacer(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)


# Minimal starfield drawn once
class _StarField extends Node2D:
	var size: Vector2 = Vector2(1280, 720)
	var _stars: Array = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		for _i in 120:
			_stars.append({
				"pos":  Vector2(rng.randf() * size.x, rng.randf() * size.y),
				"r":    rng.randf_range(0.5, 1.8),
				"a":    rng.randf_range(0.15, 0.55),
			})

	func _draw() -> void:
		for s in _stars:
			draw_circle(s["pos"], s["r"], Color(1, 1, 1, s["a"]))

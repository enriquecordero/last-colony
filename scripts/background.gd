extends Node2D

var map_w: float = 2400.0
var map_h: float = 1600.0

var _rng   := RandomNumberGenerator.new()
var _dust:  PackedVector2Array
var _dsizes: PackedFloat32Array
var _dcolors: PackedColorArray

func _ready() -> void:
	_rng.seed = 0xFE_DC_AB_12
	_bake_dust()
	queue_redraw()

func _bake_dust() -> void:
	var n := 1800
	_dust   = PackedVector2Array()
	_dsizes = PackedFloat32Array()
	_dcolors = PackedColorArray()
	for _i in n:
		_dust.append(Vector2(
			_rng.randf_range(0.0, map_w),
			_rng.randf_range(0.0, map_h)))
		_dsizes.append(_rng.randf_range(0.8, 3.2))
		var v := _rng.randf_range(0.0, 1.0)
		_dcolors.append(Color(0.28 + v * 0.12, 0.13 + v * 0.06, 0.05 + v * 0.02, 0.35 + v * 0.2))

func _draw() -> void:
	# Fine dust particles
	for i in _dust.size():
		draw_circle(_dust[i], _dsizes[i], _dcolors[i])

	# Subtle grid (barely visible — reference only)
	var gc := Color(0.22, 0.10, 0.04, 0.18)
	var s  := 80.0
	var x  := s
	while x < map_w:
		draw_line(Vector2(x, 0), Vector2(x, map_h), gc, 0.8)
		x += s
	var y := s
	while y < map_h:
		draw_line(Vector2(0, y), Vector2(map_w, y), gc, 0.8)
		y += s

	# Faint center crosshair
	draw_line(Vector2(map_w * 0.5, 0), Vector2(map_w * 0.5, map_h),
		Color(0.35, 0.14, 0.05, 0.12), 1.5)
	draw_line(Vector2(0, map_h * 0.5), Vector2(map_w, map_h * 0.5),
		Color(0.35, 0.14, 0.05, 0.12), 1.5)

	# Map border
	draw_rect(Rect2(0, 0, map_w, map_h), Color(0.50, 0.22, 0.07, 0.40), false, 4.0)

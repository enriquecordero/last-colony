extends Node2D

var map_w:    float   = 2400.0
var map_h:    float   = 1600.0
var base_pos: Vector2 = Vector2(1200.0, 800.0)

var _rng   := RandomNumberGenerator.new()
var _rocks: Array = []

func _ready() -> void:
	z_index = 1
	_rng.seed = 0xA3_D7_C9_11
	_generate()
	queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────

func _generate() -> void:
	# Large ridges (elongated)
	for _i in 5:
		_try_ridge(randf_range(110.0, 200.0), randf_range(28.0, 50.0))
	# Medium rocks
	for _i in 14:
		_try_rock(randf_range(34.0, 62.0))
	# Small boulders
	for _i in 16:
		_try_rock(randf_range(16.0, 30.0))

func _try_ridge(length: float, width: float) -> void:
	for _a in 40:
		var c := Vector2(
			_rng.randf_range(280.0, map_w - 280.0),
			_rng.randf_range(280.0, map_h - 280.0))
		if c.distance_to(base_pos) < 440.0:
			continue
		if _overlaps(c, length * 0.55):
			continue
		var angle := _rng.randf() * PI
		_add_ridge(c, angle, length, width)
		return

func _try_rock(radius: float) -> void:
	for _a in 40:
		var c := Vector2(
			_rng.randf_range(240.0, map_w - 240.0),
			_rng.randf_range(240.0, map_h - 240.0))
		if c.distance_to(base_pos) < 400.0:
			continue
		if _overlaps(c, radius * 2.2):
			continue
		_add_rock(c, radius)
		return

func _overlaps(pos: Vector2, min_dist: float) -> bool:
	for r in _rocks:
		if pos.distance_to(r.center) < min_dist + r.radius:
			return true
	return false

# ─────────────────────────────────────────────────────────────────────────────

func _make_rock_pts(center: Vector2, base_r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n   := _rng.randi_range(6, 10)
	for i in n:
		var a := TAU * i / float(n) + _rng.randf_range(-0.28, 0.28)
		var r := base_r * _rng.randf_range(0.50, 1.50)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts

func _make_ridge_pts(center: Vector2, angle: float, length: float, width: float) -> PackedVector2Array:
	var pts   := PackedVector2Array()
	var along := Vector2(cos(angle), sin(angle))
	var perp  := Vector2(-sin(angle), cos(angle))
	var n     := 10
	# top/crest edge — jagged
	for i in n:
		var t  := float(i) / float(n - 1)
		var cx := center + along * (t - 0.5) * length
		var taper := 1.0 if (t > 0.1 and t < 0.9) else lerpf(0.15, 1.0, min(t, 1.0 - t) * 10.0)
		var bump  := width * _rng.randf_range(0.55, 1.05) * taper
		pts.append(cx + perp * bump)
	# bottom edge — flatter
	for i in n:
		var t  := float(n - 1 - i) / float(n - 1)
		var cx := center + along * (t - 0.5) * length
		var taper := 1.0 if (t > 0.1 and t < 0.9) else lerpf(0.15, 1.0, min(t, 1.0 - t) * 10.0)
		pts.append(cx - perp * width * _rng.randf_range(0.15, 0.40) * taper)
	return pts

# ─────────────────────────────────────────────────────────────────────────────

func _add_rock(center: Vector2, radius: float) -> void:
	var pts := _make_rock_pts(center, radius)
	_register(center, pts, radius)

func _add_ridge(center: Vector2, angle: float, length: float, width: float) -> void:
	var pts := _make_ridge_pts(center, angle, length, width)
	_register(center, pts, length * 0.5)

func _register(center: Vector2, pts: PackedVector2Array, radius: float) -> void:
	var v := _rng.randf_range(0.0, 1.0)
	var base_col  := Color(0.24 + v * 0.08, 0.11 + v * 0.04, 0.04 + v * 0.02)
	var hi_col    := Color(base_col.r + 0.16, base_col.g + 0.09, base_col.b + 0.04)
	var crack_col := Color(base_col.r - 0.06, base_col.g - 0.03, base_col.b - 0.01)

	_rocks.append({
		"center": center,
		"pts":    pts,
		"base":   base_col,
		"hi":     hi_col,
		"crack":  crack_col,
		"radius": radius,
	})

	var local := PackedVector2Array()
	for p in pts:
		local.append(p - center)

	var sb := StaticBody2D.new()
	sb.collision_layer = 8
	sb.collision_mask  = 0
	sb.position        = center
	var cp             := CollisionPolygon2D.new()
	cp.polygon         = local
	sb.add_child(cp)
	add_child(sb)

# ─────────────────────────────────────────────────────────────────────────────

func _draw() -> void:
	for r in _rocks:
		var pts: PackedVector2Array = r["pts"]
		var n   := pts.size()

		# Ground shadow
		var shadow := PackedVector2Array()
		for p in pts:
			shadow.append(p + Vector2(5, 8))
		draw_polygon(shadow, PackedColorArray([Color(0, 0, 0, 0.30)]))

		# Base fill
		draw_polygon(pts, PackedColorArray([r["base"]]))

		# Highlight on upper-left faces
		for i in n:
			var a  := pts[i]
			var b  := pts[(i + 1) % n]
			var mid := (a + b) * 0.5
			var to_ctr := (r["center"] - mid).normalized()
			# Faces pointing away from center & upward get the highlight
			var face_n := (b - a).normalized().rotated(-PI * 0.5)
			if face_n.dot(to_ctr) < -0.3 and face_n.y < 0.2:
				draw_line(a, b, r["hi"], 2.0)

		# Crack details
		for i in n:
			if i % 3 == 1:
				var a  := pts[i]
				var b  := r["center"].lerp(a, 0.45)
				draw_line(a, b, r["crack"], 1.0)

		# Outline
		for i in n:
			draw_line(pts[i], pts[(i + 1) % n],
				Color(r["base"].r - 0.04, r["base"].g - 0.02, r["base"].b - 0.01, 0.85), 1.2)

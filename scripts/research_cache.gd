extends Node2D

signal collected(cache: Node)

const RADIUS := 13.0

var _t: float = 0.0

func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()

func collect() -> void:
	collected.emit(self)
	queue_free()

func _draw() -> void:
	var bob   := sin(_t * 2.2) * 2.5
	var pulse := 0.60 + sin(_t * 3.0) * 0.28

	var rc  := Color(0.17, 0.13, 0.10)   # ruin concrete
	var rhi := Color(0.28, 0.22, 0.16)   # ruin highlight

	# ── Cracked floor ─────────────────────────────────────────────────────────
	var floor_pts := PackedVector2Array([
		Vector2(-56, 26), Vector2(56, 26),
		Vector2(62, 36),  Vector2(-62, 36)
	])
	draw_polygon(floor_pts, PackedColorArray([Color(0.13, 0.10, 0.08)]))
	draw_line(Vector2(-32, 28), Vector2(-12, 34), Color(0.07, 0.05, 0.04), 1.0)
	draw_line(Vector2( 10, 27), Vector2( 38, 35), Color(0.07, 0.05, 0.04), 1.0)
	draw_line(Vector2( -6, 30), Vector2(  8, 36), Color(0.07, 0.05, 0.04), 1.0)

	# ── Back wall remnant ─────────────────────────────────────────────────────
	draw_rect(Rect2(-40, -48, 80, 14), rc.darkened(0.10))
	draw_line(Vector2(-40, -48), Vector2(40, -48), rhi, 1.5)
	# window opening in back wall
	draw_rect(Rect2(-13, -46, 26, 12), Color(0.06, 0.05, 0.08))
	draw_rect(Rect2(-13, -46, 26, 12), rhi, false, 1.2)
	draw_line(Vector2(0, -46), Vector2(0, -34), rhi, 1.0)
	draw_line(Vector2(-13, -40), Vector2(13, -40), rhi, 1.0)

	# ── Left wall (taller, jagged top) ───────────────────────────────────────
	var lw := PackedVector2Array([
		Vector2(-56, 30), Vector2(-36, 30),
		Vector2(-36, -34), Vector2(-40, -50),
		Vector2(-46, -44), Vector2(-50, -28),
		Vector2(-54, -12), Vector2(-56,  0)
	])
	draw_polygon(lw, PackedColorArray([rc]))
	draw_polyline(PackedVector2Array([
		Vector2(-36, 30), Vector2(-36, -34),
		Vector2(-40, -50), Vector2(-46, -44)
	]), rhi, 1.5)
	# cracks
	draw_line(Vector2(-50,  -8), Vector2(-40,  8), Color(0.07, 0.05, 0.04), 1.0)
	draw_line(Vector2(-48,  14), Vector2(-38, 22), Color(0.07, 0.05, 0.04), 1.0)
	# brickwork lines
	for bi in 4:
		draw_line(Vector2(-54, -20 + bi * 12), Vector2(-38, -20 + bi * 12),
				Color(0.10, 0.08, 0.06, 0.5), 0.8)

	# ── Right wall (partially fallen) ────────────────────────────────────────
	var rw := PackedVector2Array([
		Vector2(36, 30), Vector2(56, 30),
		Vector2(56,  8), Vector2(52,  -5),
		Vector2(46, -18), Vector2(42, -32),
		Vector2(38, -22), Vector2(36, 30)
	])
	draw_polygon(rw, PackedColorArray([rc]))
	draw_polyline(PackedVector2Array([
		Vector2(36, 30), Vector2(36, -22),
		Vector2(42, -32), Vector2(46, -18)
	]), rhi, 1.5)
	# small barred window
	draw_rect(Rect2(42, -14, 9, 11), Color(0.06, 0.05, 0.08))
	draw_rect(Rect2(42, -14, 9, 11), rhi, false, 1.2)
	for bi in 3:
		draw_line(Vector2(42 + bi * 3, -14), Vector2(42 + bi * 3, -3),
				rhi, 0.8)
	# brickwork
	for bi in 3:
		draw_line(Vector2(38, -5 + bi * 11), Vector2(54, -5 + bi * 11),
				Color(0.10, 0.08, 0.06, 0.5), 0.8)

	# ── Rubble ───────────────────────────────────────────────────────────────
	for rd in [Vector2(-28, 22), Vector2(26, 19), Vector2(-16, 25), Vector2(34, 23)]:
		draw_circle(rd, 4.5 + sin(_t * 0.7 + rd.x) * 0.3, rc.darkened(0.18))
		draw_arc(rd, 4.5, 0, TAU, 7, rhi, 1.0)

	# ── Terminal / research cache ─────────────────────────────────────────────
	var ox := 0.0
	var oy := bob - 4.0

	# glow behind terminal
	draw_circle(Vector2(ox, oy), 20.0, Color(0.25, 0.55, 0.95, 0.16 * pulse))

	# terminal body
	draw_rect(Rect2(-12 + ox, -22 + oy, 24, 30), Color(0.08, 0.12, 0.22))
	draw_rect(Rect2(-12 + ox, -22 + oy, 24, 30), Color(0.30, 0.55, 0.90, pulse), false, 2.0)

	# screen
	draw_rect(Rect2(-9 + ox, -19 + oy, 18, 16), Color(0.04, 0.14, 0.28))
	draw_rect(Rect2(-9 + ox, -19 + oy, 18, 16), Color(0.25, 0.58, 1.0, pulse * 0.45), false, 1.0)
	for li in 3:
		var ly := -16 + oy + li * 4
		draw_line(Vector2(-7 + ox, ly), Vector2(4 + ox, ly),
				Color(0.40, 0.80, 1.0, pulse * 0.75), 1.0)

	# base stand
	draw_rect(Rect2(-8 + ox,  8 + oy, 16, 4), Color(0.14, 0.20, 0.30))
	draw_rect(Rect2(-13 + ox, 11 + oy, 26, 3), Color(0.20, 0.28, 0.42))

	# blinking LED
	if sin(_t * 4.2) > 0.0:
		draw_circle(Vector2(8 + ox, -19 + oy), 2.2, Color(0.20, 1.0, 0.45))

	# ── Labels ───────────────────────────────────────────────────────────────
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-30, 50), "INVESTIGACIÓN",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.40, 0.75, 1.0, 0.9))
	draw_string(f, Vector2(-18, 62), "[F] recoger",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.60, 0.60, 0.60, 0.70))

extends Node2D

var _t: float = 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var rc       := Color(0.17, 0.13, 0.10)
	var rhi      := Color(0.28, 0.22, 0.16)
	var crack_c  := Color(0.07, 0.05, 0.04)
	var metal    := Color(0.30, 0.28, 0.24)
	var metal_hi := Color(0.50, 0.46, 0.38)
	var rebar_c  := Color(0.42, 0.36, 0.28)

	# ── Suelo industrial agrietado ────────────────────────────────────────────
	draw_rect(Rect2(-240, -10, 480, 90), Color(0.13, 0.10, 0.08))
	for ci in 6:
		var cx: float = -200.0 + ci * 78.0
		draw_line(Vector2(cx, -5), Vector2(cx + 30.0, 75), crack_c, 1.0)
	for ri in 3:
		draw_line(Vector2(-238, 10 + ri * 22), Vector2(238, 10 + ri * 22),
				Color(0.10, 0.08, 0.06, 0.35), 0.7)

	# ── Pared izquierda de fábrica ────────────────────────────────────────────
	var lsec := PackedVector2Array([
		Vector2(-240, 85), Vector2(-105, 85),
		Vector2(-105, -80), Vector2(-116, -96),
		Vector2(-130, -88), Vector2(-148, -100),
		Vector2(-165, -85), Vector2(-185, -92),
		Vector2(-240, -72)
	])
	draw_polygon(lsec, PackedColorArray([rc]))
	# Ventanas izquierdas
	draw_rect(Rect2(-225, -58, 32, 24), Color(0.06, 0.05, 0.08))
	draw_rect(Rect2(-225, -58, 32, 24), rhi, false, 1.0)
	draw_line(Vector2(-209, -58), Vector2(-209, -34), rhi, 0.8)
	draw_rect(Rect2(-182, -54, 28, 22), Color(0.06, 0.05, 0.08))
	draw_rect(Rect2(-182, -54, 28, 22), rhi, false, 1.0)
	# Ladrillos en pared izq
	for bi in 6:
		draw_line(Vector2(-238, -38 + bi * 16), Vector2(-107, -38 + bi * 16),
				Color(0.10, 0.08, 0.06, 0.40), 0.7)
	# Rebares en tope roto
	draw_line(Vector2(-116, -96), Vector2(-114, -112), rebar_c, 1.5)
	draw_line(Vector2(-148, -100), Vector2(-152, -118), rebar_c, 1.5)

	# ── Pared derecha (más destruida) ────────────────────────────────────────
	var rsec := PackedVector2Array([
		Vector2(105, 85), Vector2(210, 85),
		Vector2(210, -45), Vector2(200, -58),
		Vector2(185, -50), Vector2(172, -65),
		Vector2(156, -55), Vector2(138, -72),
		Vector2(118, -60), Vector2(105, -48)
	])
	draw_polygon(rsec, PackedColorArray([rc]))
	draw_rect(Rect2(115, -42, 30, 22), Color(0.06, 0.05, 0.08))
	draw_rect(Rect2(115, -42, 30, 22), rhi, false, 1.0)
	draw_line(Vector2(130, -42), Vector2(130, -20), rhi, 0.8)
	for bi in 4:
		draw_line(Vector2(107, -24 + bi * 16), Vector2(208, -24 + bi * 16),
				Color(0.10, 0.08, 0.06, 0.40), 0.7)
	draw_line(Vector2(172, -65), Vector2(174, -80), rebar_c, 1.5)
	draw_line(Vector2(138, -72), Vector2(135, -88), rebar_c, 1.5)

	# ── Silo industrial (izquierda) ───────────────────────────────────────────
	var silo_c := Vector2(-268, 22)
	var silo_r := 26.0
	draw_arc(silo_c, silo_r, 0, TAU, 24, rc.darkened(0.1), silo_r * 2.0)
	draw_arc(silo_c, silo_r, 0, TAU, 24, metal_hi, 2.0)
	for ri in 4:
		draw_arc(silo_c + Vector2(0, -14 + ri * 10), silo_r,
				-PI * 0.65, PI * 0.65, 10, metal_hi * Color(1,1,1,0.5), 1.4)
	# Escalera de mano al costado
	for li in 5:
		draw_line(silo_c + Vector2(silo_r, -12 + li * 7),
				silo_c + Vector2(silo_r + 8, -12 + li * 7), metal, 1.0)
	draw_line(silo_c + Vector2(silo_r + 4, -15),
			silo_c + Vector2(silo_r + 4, 22), metal, 1.0)
	# Domo
	draw_arc(silo_c + Vector2(0, -silo_r + 1), silo_r * 0.65,
			PI, TAU, 14, rc, silo_r * 1.2)
	draw_arc(silo_c + Vector2(0, -silo_r + 1), silo_r * 0.65,
			PI, TAU, 14, metal_hi, 1.5)

	# ── Pilar central derrumbado ──────────────────────────────────────────────
	# Stub del pilar aún en pie
	draw_rect(Rect2(-20, -88, 40, 148), rc.darkened(0.08))
	draw_rect(Rect2(-20, -88, 40, 148), rhi, false, 1.5)
	draw_rect(Rect2(-30, -98, 60, 14), rc.lightened(0.06))
	draw_rect(Rect2(-30, -98, 60, 14), rhi, false, 1.5)
	draw_line(Vector2(-5, -82), Vector2(8, -50), crack_c, 1.2)
	draw_line(Vector2(4, -55), Vector2(16, -22), crack_c, 1.0)
	# Sección caída en el suelo
	var fallen := PackedVector2Array([
		Vector2(30, 70), Vector2(80, 62),
		Vector2(118, 66), Vector2(120, 78),
		Vector2(82, 84), Vector2(28, 82)
	])
	draw_polygon(fallen, PackedColorArray([rc.darkened(0.18)]))
	draw_polyline(fallen, rhi, 1.0)

	# ── Escombros en suelo ────────────────────────────────────────────────────
	for rd in [Vector2(-85, 72), Vector2(72, 68), Vector2(-35, 78),
			   Vector2(148, 65), Vector2(-160, 70), Vector2(28, 76)]:
		draw_circle(rd, 5.5 + sin(_t * 0.4 + rd.x) * 0.4, rc.darkened(0.22))
		draw_arc(rd, 5.5, 0, TAU, 7, rhi, 0.8)

	# ── Franja de advertencia en suelo ───────────────────────────────────────
	for si in 9:
		var sx: float = -180.0 + si * 44.0
		if (si % 2) == 0:
			draw_rect(Rect2(sx, 70.0, 38.0, 10.0), Color(0.65, 0.50, 0.0, 0.30))

extends Node2D

# 0 = watchtower  1 = checkpoint  2 = vehicle hulk
var decor_type: int = 0

var _t: float = 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	match decor_type:
		0: _draw_watchtower()
		1: _draw_checkpoint()
		2: _draw_vehicle()

func _draw_watchtower() -> void:
	var rc      := Color(0.17, 0.13, 0.10)
	var rhi     := Color(0.28, 0.22, 0.16)
	var rebar_c := Color(0.42, 0.36, 0.28)

	# Plataforma superior derrumbada
	var top_pts := PackedVector2Array([
		Vector2(-30, -72), Vector2(28, -72),
		Vector2(34, -62), Vector2(-36, -62)
	])
	draw_polygon(top_pts, PackedColorArray([rc.darkened(0.05)]))
	draw_polyline(top_pts + PackedVector2Array([top_pts[0]]), rhi, 1.2)
	# Barandal roto
	draw_line(Vector2(-30, -72), Vector2(-30, -82), rhi, 2.0)
	draw_line(Vector2(-30, -82), Vector2(6, -82),   rhi, 2.0)
	draw_line(Vector2(28, -72),  Vector2(28, -78),   rhi, 2.0)
	# Poste central (inclinado)
	var pole_top := Vector2(4, -115)
	var pole_bot := Vector2(0, -12)
	draw_line(pole_bot, pole_top, rc.lightened(0.06), 7.0)
	draw_line(pole_bot, pole_top, rhi, 1.5)
	# Travesaños del poste
	for i in 3:
		var py: float = -30.0 - i * 22.0
		draw_line(Vector2(-10, py), Vector2(12, py + 2), rebar_c, 2.0)
	# Rebares en tope
	draw_line(pole_top, pole_top + Vector2(-5, -14), rebar_c, 1.5)
	draw_line(pole_top, pole_top + Vector2( 8, -10), rebar_c, 1.5)
	# Base de hormigón
	draw_rect(Rect2(-22, -14, 44, 18), rc)
	draw_rect(Rect2(-22, -14, 44, 18), rhi, false, 1.2)
	draw_rect(Rect2(-30,   2, 60, 10), rc.darkened(0.08))
	draw_rect(Rect2(-30,   2, 60, 10), rhi, false, 1.0)
	# Grietas
	draw_line(Vector2(-10, -12), Vector2(4, 0),   Color(0.07, 0.05, 0.04), 1.0)
	draw_line(Vector2(10, -10),  Vector2(22, -2), Color(0.07, 0.05, 0.04), 0.8)

func _draw_checkpoint() -> void:
	var rc   := Color(0.17, 0.13, 0.10)
	var rhi  := Color(0.28, 0.22, 0.16)
	var gray := Color(0.32, 0.30, 0.26)

	# Caseta de guardia (derrumbada)
	draw_rect(Rect2(-36, -40, 38, 46), rc.darkened(0.05))
	draw_rect(Rect2(-36, -40, 38, 46), rhi, false, 1.2)
	# Ventana rota
	draw_rect(Rect2(-26, -34, 16, 12), Color(0.06, 0.05, 0.08))
	draw_rect(Rect2(-26, -34, 16, 12), rhi, false, 1.0)
	draw_line(Vector2(-18, -34), Vector2(-22, -22), Color(0.07,0.05,0.04), 0.8)
	# Techo caído
	var roof := PackedVector2Array([
		Vector2(-40, -40), Vector2(6, -40),
		Vector2(14, -52), Vector2(-40, -48)
	])
	draw_polygon(roof, PackedColorArray([rc.darkened(0.10)]))
	draw_polyline(roof + PackedVector2Array([roof[0]]), rhi, 1.0)

	# Barrera horizontal (pluma caída)
	var bar_angle := deg_to_rad(-25.0)
	var bar_len   := 90.0
	var bar_orig  := Vector2(14, -22)
	var bar_end   := bar_orig + Vector2(cos(bar_angle), sin(bar_angle)) * bar_len
	# Stripes amarillo-negro
	var seg_len := 12.0
	var bar_dir := (bar_end - bar_orig).normalized()
	for si in int(bar_len / seg_len):
		var seg_start: Vector2 = bar_orig + bar_dir * (si * seg_len)
		var seg_stop:  Vector2 = bar_orig + bar_dir * (minf((si + 1) * seg_len, bar_len))
		var stripe_col := Color(0.75, 0.60, 0.0) if (si % 2 == 0) else gray
		draw_line(seg_start, seg_stop, stripe_col, 5.0)
	# Post de la pluma
	draw_line(bar_orig, bar_orig + Vector2(0, 18), gray, 5.0)
	draw_rect(Rect2(bar_orig.x - 8, bar_orig.y + 16, 16, 8), gray)

	# Conos tirados en el suelo
	for ci in 3:
		var cp := Vector2(30.0 + ci * 24.0, 2.0)
		draw_circle(cp, 7.0, Color(0.75, 0.30, 0.05, 0.75))
		draw_line(cp + Vector2(0, -7), cp + Vector2(0, 7), Color(0.85, 0.85, 0.85, 0.5), 1.0)

func _draw_vehicle() -> void:
	var rc      := Color(0.17, 0.13, 0.10)
	var rhi     := Color(0.28, 0.22, 0.16)
	var metal   := Color(0.26, 0.24, 0.20)
	var rust    := Color(0.38, 0.20, 0.06)
	var char_c  := Color(0.08, 0.07, 0.06)

	# Sombra
	draw_rect(Rect2(-50, 14, 100, 12), Color(0, 0, 0, 0.35))
	# Carrocería principal (quemada, oscura)
	draw_rect(Rect2(-48, -18, 96, 32), char_c)
	draw_rect(Rect2(-48, -18, 96, 32), rust, false, 1.5)
	# Techo aplastado
	var roof_pts := PackedVector2Array([
		Vector2(-32, -18), Vector2(30, -18),
		Vector2(24, -36),  Vector2(-26, -34)
	])
	draw_polygon(roof_pts, PackedColorArray([char_c.lightened(0.04)]))
	draw_polyline(roof_pts + PackedVector2Array([roof_pts[0]]), rust, 1.2)
	# Ventanas rotas (ahumadas)
	draw_rect(Rect2(-28, -33, 24, 14), Color(0.04, 0.04, 0.04))
	draw_rect(Rect2(-28, -33, 24, 14), rust * Color(1,1,1,0.5), false, 0.8)
	draw_rect(Rect2(  2, -33, 18, 14), Color(0.04, 0.04, 0.04))
	draw_rect(Rect2(  2, -33, 18, 14), rust * Color(1,1,1,0.5), false, 0.8)
	# Ruedas (desinfladas, aplastadas)
	for wx: float in [-30.0, 30.0]:
		draw_arc(Vector2(wx, 14), 12.0, 0, TAU, 14, metal, 12.0)
		draw_arc(Vector2(wx, 14), 5.0, 0, TAU, 10, metal.darkened(0.2), 4.0)
	# Manchas de quemado
	for bi in 4:
		var bx: float = -35.0 + bi * 22.0
		draw_circle(Vector2(bx, -5), 8.0 + sin(_t * 0.3 + bx) * 0.5,
				Color(0.06, 0.05, 0.04, 0.65))
	# Puerta arrancada en el suelo
	var door_pts := PackedVector2Array([
		Vector2(52, 8), Vector2(78, 4),
		Vector2(82, 20), Vector2(56, 24)
	])
	draw_polygon(door_pts, PackedColorArray([metal.darkened(0.15)]))
	draw_polyline(door_pts + PackedVector2Array([door_pts[0]]), rust, 1.0)

extends Control

const PANEL_W := 200.0
const PANEL_H := 134.0
const PAD     := 6.0

var player:          Node2D
var enemies_node:    Node2D
var friendlies_node: Node2D
var base_pos:        Vector2 = Vector2.ZERO
var map_w:           float   = 2400.0
var map_h:           float   = 1600.0
var threat_dir:      Vector2 = Vector2.ZERO
var crates_node:     Node2D
var satellite_revealed: bool  = false
var _mm_burrows:     Array    = []
var _mm_satellite:   Node2D   = null
var _mm_research:    Array    = []
var _mm_guardian:    Node2D   = null

func _ready() -> void:
	custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	mouse_filter        = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _world_to_minimap(world: Vector2) -> Vector2:
	var inner_w := PANEL_W - PAD * 2.0
	var inner_h := PANEL_H - PAD * 2.0
	var x: float = PAD + clampf(world.x / map_w, 0.0, 1.0) * inner_w
	var y: float = PAD + clampf(world.y / map_h, 0.0, 1.0) * inner_h
	return Vector2(x, y)

func _draw() -> void:
	draw_rect(Rect2(0, 0, PANEL_W, PANEL_H), Color(0.04, 0.07, 0.11, 0.92))
	draw_rect(Rect2(0, 0, PANEL_W, PANEL_H), Color(0.30, 0.45, 0.55, 0.85), false, 1.5)

	var cx := PANEL_W * 0.5
	var cy := PANEL_H * 0.5
	draw_line(Vector2(cx, PAD), Vector2(cx, PANEL_H - PAD),
		Color(0.20, 0.30, 0.35, 0.4), 0.8)
	draw_line(Vector2(PAD, cy), Vector2(PANEL_W - PAD, cy),
		Color(0.20, 0.30, 0.35, 0.4), 0.8)

	if threat_dir != Vector2.ZERO:
		var center := Vector2(cx, cy)
		var radius: float = min(PANEL_W, PANEL_H) * 0.42
		var tip: Vector2  = center + threat_dir * radius
		var perp: Vector2 = Vector2(-threat_dir.y, threat_dir.x) * 6.0
		var p1: Vector2   = tip
		var p2: Vector2   = tip - threat_dir * 13.0 + perp
		var p3: Vector2   = tip - threat_dir * 13.0 - perp
		var pulse: float  = 0.55 + sin(Time.get_ticks_msec() * 0.005) * 0.20
		draw_polygon([p1, p2, p3], [Color(1.0, 0.40, 0.20, pulse)])

	if base_pos != Vector2.ZERO:
		var bp := _world_to_minimap(base_pos)
		draw_rect(Rect2(bp - Vector2(5, 5), Vector2(10, 10)),
			Color(0.20, 0.85, 0.45))
		draw_rect(Rect2(bp - Vector2(5, 5), Vector2(10, 10)),
			Color(0.55, 1.0, 0.65, 0.85), false, 1.0)

	# Crates (cuadraditos — verde=biomasa, cian=medkit, naranja=bomba)
	if is_instance_valid(crates_node):
		for c in crates_node.get_children():
			if not is_instance_valid(c):
				continue
			var crate_type: Variant = c.get("type")
			var cp  := _world_to_minimap(c.global_position)
			var col := Color(0.85, 0.95, 0.85)
			if crate_type == 1:
				col = Color(0.25, 0.85, 1.00)
			elif crate_type == 2:
				col = Color(1.0, 0.45, 0.15)
			draw_rect(Rect2(cp - Vector2(3, 3), Vector2(6, 6)), col)

	if is_instance_valid(enemies_node):
		for e in enemies_node.get_children():
			if not is_instance_valid(e):
				continue
			var ep := _world_to_minimap(e.global_position)
			draw_circle(ep, 1.8, Color(1.0, 0.25, 0.20))

	if is_instance_valid(friendlies_node):
		for n in friendlies_node.get_children():
			if not is_instance_valid(n):
				continue
			var col := Color(0.55, 0.55, 0.55)
			var role: Variant = n.get("role")
			if role == "ASSAULT":
				col = Color(0.45, 0.75, 1.0)
			elif role == "MEDIC":
				col = Color(0.30, 1.0, 0.55)
			elif role == "ENGINEER":
				col = Color(1.0, 0.65, 0.20)
			if n.get("down") == true:
				col = Color(0.55, 0.45, 0.45)
			var npc_pos := _world_to_minimap(n.global_position)
			draw_circle(npc_pos, 2.5, col)

	if is_instance_valid(player):
		var pp := _world_to_minimap(player.global_position)
		draw_circle(pp, 3.5, Color(1.0, 1.0, 0.30))
		draw_arc(pp, 5.0, 0, TAU, 16, Color(1.0, 1.0, 0.50, 0.90), 1.2)

	# Mission objects — faint blips always, full color after satellite activated
	for b in _mm_burrows:
		if is_instance_valid(b):
			var bp2 := _world_to_minimap(b.global_position)
			if satellite_revealed:
				draw_circle(bp2, 3.5, Color(0.65, 0.20, 0.90, 0.85))
				draw_arc(bp2, 5.0, 0, TAU, 12, Color(0.75, 0.30, 1.0, 0.6), 1.0)
			else:
				draw_circle(bp2, 2.5, Color(0.75, 0.75, 0.75, 0.28))
	for rc in _mm_research:
		if is_instance_valid(rc):
			var rp := _world_to_minimap(rc.global_position)
			if satellite_revealed:
				draw_rect(Rect2(rp - Vector2(3.5, 3.5), Vector2(7, 7)),
					Color(0.30, 0.70, 1.0, 0.85))
			else:
				draw_rect(Rect2(rp - Vector2(2, 2), Vector2(4, 4)),
					Color(0.75, 0.75, 0.75, 0.28))
	if is_instance_valid(_mm_satellite):
		var sp := _world_to_minimap(_mm_satellite.global_position)
		if satellite_revealed:
			draw_circle(sp, 4.0, Color(0.30, 0.80, 1.0, 0.9))
			draw_arc(sp, 6.5, 0, TAU, 12, Color(0.50, 0.90, 1.0, 0.7), 1.2)
		else:
			draw_circle(sp, 2.5, Color(0.75, 0.75, 0.75, 0.28))
	if is_instance_valid(_mm_guardian):
		var gp := _world_to_minimap(_mm_guardian.global_position)
		if satellite_revealed:
			draw_circle(gp, 5.0, Color(0.95, 0.40, 0.10, 0.9))
			draw_arc(gp, 7.5, 0, TAU, 16, Color(1.0, 0.55, 0.20, 0.7), 1.5)
		else:
			draw_circle(gp, 3.0, Color(0.75, 0.75, 0.75, 0.28))

	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(0, -3), "RADAR",
		HORIZONTAL_ALIGNMENT_CENTER, PANEL_W, 11,
		Color(0.55, 0.75, 0.90, 0.85))

func init(p: Node2D, en: Node2D, fr: Node2D, base: Vector2, m_w: float, m_h: float) -> void:
	player          = p
	enemies_node    = en
	friendlies_node = fr
	base_pos        = base
	map_w           = m_w
	map_h           = m_h

func set_threat_dir(dir: Vector2) -> void:
	threat_dir = dir

func set_crates_node(node: Node2D) -> void:
	crates_node = node

func set_satellite_revealed(v: bool) -> void:
	satellite_revealed = v

func set_mission_objects(burrows: Array, sat: Node2D, research: Array, guardian: Node2D) -> void:
	_mm_burrows   = burrows
	_mm_satellite = sat
	_mm_research  = research
	_mm_guardian  = guardian

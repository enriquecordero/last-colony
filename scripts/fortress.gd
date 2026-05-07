extends Node2D
class_name Fortress

# ─────────────────────────────────────────────────────────────────────────────
# Fortress — octagon central hub with N/E/W arm corridors and a solid south
# wall. Arm side-walls and the south wall are damageable FortWall nodes so
# enemies can breach them and the engineer has something to repair.
# ─────────────────────────────────────────────────────────────────────────────

const OCT_RADIUS := 120.0   # center → octagon vertex
const ARM_W      := 66.0    # corridor width
const ARM_LEN    := 120.0   # arm length from octagon face to door
const SOUTH_W    := 200.0   # solid south wall width
const SOUTH_H    := 44.0    # solid south wall height
const TOWER_L2_W := 110.0
const TOWER_L2_H := 48.0
const TOWER_L3_W := 74.0
const TOWER_L3_H := 42.0
const STAIR_SIZE := 30.0
const CORE_R     := 28.0

# ── Colors ──
const COL_FLOOR_0      := Color(0.10, 0.13, 0.18)
const COL_FLOOR_0_EDGE := Color(0.20, 0.26, 0.34)
const COL_FLOOR_1      := Color(0.13, 0.17, 0.23)
const COL_FLOOR_1_EDGE := Color(0.30, 0.40, 0.55)
const COL_FLOOR_2      := Color(0.16, 0.22, 0.32)
const COL_FLOOR_2_EDGE := Color(0.45, 0.60, 0.75)
const COL_TOWER        := Color(0.24, 0.34, 0.50)
const COL_TOWER_EDGE   := Color(0.66, 0.78, 0.88)
const COL_WALL_EDGE    := Color(0.36, 0.41, 0.47)
const COL_GATE_LINE    := Color(1.0,  0.85, 0.20, 0.85)
const COL_AMBER        := Color(1.0,  0.55, 0.0)
const COL_STAIR        := Color(0.13, 0.20, 0.29)
const COL_STAIR_EDGE   := Color(0.55, 0.70, 0.85)
const COL_CORE_OUTER   := Color(0.0,  0.83, 1.0)
const COL_CORE_INNER   := Color(0.55, 0.95, 1.0)
const COL_CRACK        := Color(0.92, 0.70, 0.30, 0.80)

# ── Station types ──
enum StationType { TALLER, GENERATOR, ENFERMERIA }

class Slot:
	var pos:    Vector2
	var size:   Vector2
	var stype:  int
	var built:  bool = false
	var hp:     int  = 0
	var max_hp: int  = 300
	var color:  Color
	var label:  String

# ── Damageable wall segment ──
class FortWall extends StaticBody2D:
	var hp:     int = 300
	var max_hp: int = 300

	func init_wall(wall_size: Vector2) -> void:
		collision_layer = 8
		collision_mask  = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = wall_size
		cs.shape = rs
		add_child(cs)

	func take_damage(amount: int) -> void:
		hp = maxi(0, hp - amount)
		if hp == 0:
			for cs in get_children():
				if cs is CollisionShape2D:
					(cs as CollisionShape2D).disabled = true

# ── Geometry (global coords) ──
var hex_center:        Vector2
var hex_vertices:      Array
var arm_polygons:      Dictionary
var door_centers:      Dictionary
var platform_polygons: Array = []
var south_wall_rect:   Rect2
var tower_l2_rect:     Rect2
var tower_l3_rect:     Rect2
var stair_zones:       Array = []
var slots:             Array = []

var _apo: float   # OCT_RADIUS * cos(22.5°) ≈ 110.87
var _fort_walls: Array = []
var _pulse_t: float = 0.0


func _ready() -> void:
	z_index = 0
	_apo = OCT_RADIUS * cos(deg_to_rad(22.5))
	_build_geometry()
	_build_collision()
	set_process(true)


func _process(delta: float) -> void:
	_pulse_t += delta
	queue_redraw()


# ─────────────────────────────────────────────────────────────────────────────
# Geometry
# ─────────────────────────────────────────────────────────────────────────────

func _build_geometry() -> void:
	hex_center = global_position
	var c  := hex_center
	var hw := ARM_W * 0.5   # 33

	# Octagon vertices: 22.5 + 45*i degrees
	# V0=(APO,46) V1=(46,APO) V2=(-46,APO) V3=(-APO,46)
	# V4=(-APO,-46) V5=(-46,-APO) V6=(46,-APO) V7=(APO,-46)
	# N-face midpoint: (0,-APO)  E: (APO,0)  S: (0,APO)  W: (-APO,0)
	hex_vertices = []
	for i in 8:
		var a: float = deg_to_rad(22.5 + 45.0 * float(i))
		hex_vertices.append(c + Vector2(cos(a), sin(a)) * OCT_RADIUS)

	arm_polygons = {
		"N": [
			c + Vector2(-hw,        -_apo),
			c + Vector2(-hw,        -_apo - ARM_LEN),
			c + Vector2( hw,        -_apo - ARM_LEN),
			c + Vector2( hw,        -_apo),
		],
		"E": [
			c + Vector2(_apo,            -hw),
			c + Vector2(_apo + ARM_LEN,  -hw),
			c + Vector2(_apo + ARM_LEN,   hw),
			c + Vector2(_apo,             hw),
		],
		"W": [
			c + Vector2(-_apo - ARM_LEN, -hw),
			c + Vector2(-_apo,           -hw),
			c + Vector2(-_apo,            hw),
			c + Vector2(-_apo - ARM_LEN,  hw),
		],
	}

	door_centers = {
		"N": c + Vector2(0.0,                    -_apo - ARM_LEN + 10.0),
		"E": c + Vector2(_apo + ARM_LEN - 10.0,   0.0),
		"W": c + Vector2(-_apo - ARM_LEN + 10.0,  0.0),
	}

	south_wall_rect = Rect2(
		c + Vector2(-SOUTH_W * 0.5, _apo),
		Vector2(SOUTH_W, SOUTH_H))

	# Tower sits visually above the south wall (lower Y = higher on screen)
	tower_l2_rect = Rect2(
		c + Vector2(-TOWER_L2_W * 0.5, _apo - TOWER_L2_H - 6.0),
		Vector2(TOWER_L2_W, TOWER_L2_H))
	tower_l3_rect = Rect2(
		c + Vector2(-TOWER_L3_W * 0.5, _apo - TOWER_L2_H - TOWER_L3_H - 10.0),
		Vector2(TOWER_L3_W, TOWER_L3_H))

	platform_polygons = []

	# ── Stair zones ──
	stair_zones = []
	stair_zones.append({
		"rect": Rect2(south_wall_rect.position - Vector2(STAIR_SIZE + 2.0, 0),
			Vector2(STAIR_SIZE, south_wall_rect.size.y)),
		"from_level": 0, "to_level": 1, "plat_idx": -1
	})
	stair_zones.append({
		"rect": Rect2(south_wall_rect.position + Vector2(south_wall_rect.size.x + 2.0, 0),
			Vector2(STAIR_SIZE, south_wall_rect.size.y)),
		"from_level": 0, "to_level": 1, "plat_idx": -1
	})
	stair_zones.append({
		"rect": Rect2(c + Vector2(-10.0, _apo - 6.0), Vector2(20.0, 20.0)),
		"from_level": 1, "to_level": 2, "plat_idx": -2
	})
	stair_zones.append({
		"rect": Rect2(c + Vector2(-10.0, _apo - TOWER_L2_H - 10.0), Vector2(20.0, 20.0)),
		"from_level": 2, "to_level": 3, "plat_idx": -3
	})

	# ── Station slots ──
	slots = []
	var taller     := Slot.new()
	taller.pos      = c + Vector2(-38.0, -50.0)
	taller.size     = Vector2(50.0, 36.0)
	taller.stype    = StationType.TALLER
	taller.color    = Color(0.80, 0.45, 0.20)
	taller.label    = "TALLER"
	slots.append(taller)

	var generator  := Slot.new()
	generator.pos   = c + Vector2(38.0, -50.0)
	generator.size  = Vector2(50.0, 36.0)
	generator.stype = StationType.GENERATOR
	generator.color = Color(0.0, 0.83, 1.0)
	generator.label = "GENER."
	slots.append(generator)

	var enfermeria := Slot.new()
	enfermeria.pos   = c + Vector2(0.0, 50.0)
	enfermeria.size  = Vector2(50.0, 36.0)
	enfermeria.stype = StationType.ENFERMERIA
	enfermeria.color = Color(0.22, 1.0, 0.30)
	enfermeria.label = "ENFERM."
	slots.append(enfermeria)


# ─────────────────────────────────────────────────────────────────────────────
# Collision
# ─────────────────────────────────────────────────────────────────────────────

func _build_collision() -> void:
	var hw := ARM_W * 0.5
	const T := 8.0

	_fort_walls = []
	# N arm left and right walls
	_add_fort_wall(Vector2(-hw,  -_apo - ARM_LEN * 0.5), Vector2(T, ARM_LEN))
	_add_fort_wall(Vector2( hw,  -_apo - ARM_LEN * 0.5), Vector2(T, ARM_LEN))
	# E arm top and bottom walls
	_add_fort_wall(Vector2(_apo + ARM_LEN * 0.5, -hw),   Vector2(ARM_LEN, T))
	_add_fort_wall(Vector2(_apo + ARM_LEN * 0.5,  hw),   Vector2(ARM_LEN, T))
	# W arm top and bottom walls
	_add_fort_wall(Vector2(-_apo - ARM_LEN * 0.5, -hw),  Vector2(ARM_LEN, T))
	_add_fort_wall(Vector2(-_apo - ARM_LEN * 0.5,  hw),  Vector2(ARM_LEN, T))
	# South wall (solid face)
	_add_fort_wall(Vector2(0.0, _apo + SOUTH_H * 0.5),   Vector2(SOUTH_W, SOUTH_H))

	# Corner gap-fillers (regular static bodies)
	_add_wall_seg(Vector2( hw,              -_apo),  Vector2( _apo,              -hw))  # NE
	_add_wall_seg(Vector2(-_apo,            -hw),    Vector2(-hw,               -_apo)) # NW
	_add_wall_seg(Vector2( _apo,             hw),    Vector2( SOUTH_W * 0.5,    _apo))  # SE
	_add_wall_seg(Vector2(-SOUTH_W * 0.5,   _apo),  Vector2(-_apo,              hw))   # SW


func _add_fort_wall(local_center: Vector2, wall_size: Vector2) -> void:
	var fw := FortWall.new()
	fw.position = local_center
	fw.init_wall(wall_size)
	_fort_walls.append(fw)
	add_child(fw)


func _add_wall_seg(from_pt: Vector2, to_pt: Vector2) -> void:
	var sb   := StaticBody2D.new()
	sb.collision_layer = 8
	sb.collision_mask  = 0
	var cs   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var diff := to_pt - from_pt
	rect.size   = Vector2(diff.length(), 10.0)
	cs.position = (from_pt + to_pt) * 0.5
	cs.rotation = diff.angle()
	cs.shape    = rect
	sb.add_child(cs)
	add_child(sb)


# ─────────────────────────────────────────────────────────────────────────────
# Drawing
# ─────────────────────────────────────────────────────────────────────────────

func _draw() -> void:
	var c := -global_position + hex_center  # == Vector2.ZERO

	# 1) Arms (floor 0) — drawn first so octagon overlaps
	for k in arm_polygons:
		var poly: Array = arm_polygons[k]
		var lp := PackedVector2Array()
		for v in poly:
			lp.append(v - global_position)
		draw_colored_polygon(lp, COL_FLOOR_0)
		draw_polyline(lp + PackedVector2Array([lp[0]]), COL_FLOOR_0_EDGE, 1.5)

	# 2) South wall (floor 1)
	var sw := Rect2(south_wall_rect.position - global_position, south_wall_rect.size)
	draw_rect(Rect2(sw.position + Vector2(0, 4), sw.size), Color(0, 0, 0, 0.5))
	draw_rect(sw, COL_FLOOR_1)
	draw_rect(sw, COL_FLOOR_1_EDGE, false, 2.0)
	draw_line(sw.position + Vector2(0, 8),
		sw.position + Vector2(sw.size.x, 8), COL_FLOOR_1_EDGE, 0.8)
	var hazard := Color(0.72, 0.55, 0.0, 0.55)
	for si in 6:
		var sx: float = sw.position.x + 6.0 + si * 30.0
		if sx + 14.0 > sw.position.x + sw.size.x - 6.0:
			break
		if si % 2 == 0:
			var sp := PackedVector2Array([
				Vector2(sx,        sw.position.y + 6),
				Vector2(sx + 14.0, sw.position.y + 6),
				Vector2(sx + 10.0, sw.position.y + sw.size.y - 6),
				Vector2(sx - 4.0,  sw.position.y + sw.size.y - 6),
			])
			draw_colored_polygon(sp, hazard)

	# 3) Octagon central body
	var oct := PackedVector2Array()
	for v in hex_vertices:
		oct.append(v - global_position)
	draw_colored_polygon(oct, COL_FLOOR_0)
	draw_polyline(oct + PackedVector2Array([oct[0]]), COL_FLOOR_0_EDGE, 2.0)
	draw_line(c + Vector2(-OCT_RADIUS * 0.7, 0), c + Vector2(OCT_RADIUS * 0.7, 0),
		Color(0.20, 0.26, 0.34, 0.35), 0.8)
	draw_line(c + Vector2(0, -OCT_RADIUS * 0.7), c + Vector2(0, OCT_RADIUS * 0.7),
		Color(0.20, 0.26, 0.34, 0.35), 0.8)

	# 4) Arm wall lines
	_draw_arm_walls()

	# 5) Gates
	_draw_gates()

	# 6) Tower
	_draw_tower()

	# 7) Stairs
	_draw_stairs()

	# 8) Station slots
	for slot in slots:
		_draw_slot(slot)

	# 9) Core
	_draw_core(c)

	# 10) Antenna
	_draw_antennas()

	# 11) Bunker details
	_draw_bunker_details(c)

	# 12) Wall damage overlay
	_draw_wall_damage()


func _draw_arm_walls() -> void:
	var gp := global_position

	var arm_n: Array = arm_polygons["N"]
	var n_bl := arm_n[0] - gp
	var n_tl := arm_n[1] - gp
	var n_tr := arm_n[2] - gp
	var n_br := arm_n[3] - gp
	draw_line(n_tl, n_bl, COL_WALL_EDGE, 4.0)
	draw_line(n_tr, n_br, COL_WALL_EDGE, 4.0)
	draw_line(n_tl, n_tl + Vector2(8,  0),  COL_WALL_EDGE, 4.0)
	draw_line(n_tr, n_tr + Vector2(-8, 0),  COL_WALL_EDGE, 4.0)

	var arm_e: Array = arm_polygons["E"]
	var e_tl := arm_e[0] - gp
	var e_tr := arm_e[1] - gp
	var e_br := arm_e[2] - gp
	var e_bl := arm_e[3] - gp
	draw_line(e_tl, e_tr, COL_WALL_EDGE, 4.0)
	draw_line(e_bl, e_br, COL_WALL_EDGE, 4.0)
	draw_line(e_tr, e_tr + Vector2(0,  8),  COL_WALL_EDGE, 4.0)
	draw_line(e_br, e_br + Vector2(0, -8),  COL_WALL_EDGE, 4.0)

	var arm_w: Array = arm_polygons["W"]
	var w_tl := arm_w[0] - gp
	var w_tr := arm_w[1] - gp
	var w_br := arm_w[2] - gp
	var w_bl := arm_w[3] - gp
	draw_line(w_tl, w_tr, COL_WALL_EDGE, 4.0)
	draw_line(w_bl, w_br, COL_WALL_EDGE, 4.0)
	draw_line(w_tl, w_tl + Vector2(0,  8),  COL_WALL_EDGE, 4.0)
	draw_line(w_bl, w_bl + Vector2(0, -8),  COL_WALL_EDGE, 4.0)


func _draw_gates() -> void:
	var pulse: float = 0.6 + 0.4 * (sin(_pulse_t * 4.0) * 0.5 + 0.5)
	var gp := global_position

	var gn: Vector2 = door_centers["N"] - gp
	draw_line(gn + Vector2(-28, 0), gn + Vector2(28, 0), COL_GATE_LINE, 2.5)
	draw_circle(gn + Vector2(-32, 0), 3.0, COL_AMBER * Color(1, 1, 1, pulse))
	draw_circle(gn + Vector2( 32, 0), 3.0, COL_AMBER * Color(1, 1, 1, pulse))

	var ge: Vector2 = door_centers["E"] - gp
	draw_line(ge + Vector2(0, -28), ge + Vector2(0, 28), COL_GATE_LINE, 2.5)
	draw_circle(ge + Vector2(0, -32), 3.0, COL_AMBER * Color(1, 1, 1, pulse))
	draw_circle(ge + Vector2(0,  32), 3.0, COL_AMBER * Color(1, 1, 1, pulse))

	var gw: Vector2 = door_centers["W"] - gp
	draw_line(gw + Vector2(0, -28), gw + Vector2(0, 28), COL_GATE_LINE, 2.5)
	draw_circle(gw + Vector2(0, -32), 3.0, COL_AMBER * Color(1, 1, 1, pulse))
	draw_circle(gw + Vector2(0,  32), 3.0, COL_AMBER * Color(1, 1, 1, pulse))


func _draw_stairs() -> void:
	for sz in stair_zones:
		var sr: Rect2 = sz["rect"]
		var sl := Rect2(sr.position - global_position, sr.size)
		draw_rect(sl, COL_STAIR)
		draw_rect(sl, COL_STAIR_EDGE, false, 1.0)
		for i in 3:
			var y: float = sl.position.y + sl.size.y * (float(i + 1) / 4.0)
			draw_line(Vector2(sl.position.x + 2, y),
				Vector2(sl.position.x + sl.size.x - 2, y),
				COL_STAIR_EDGE * Color(1, 1, 1, 0.55), 0.7)


func _draw_tower() -> void:
	var l2 := Rect2(tower_l2_rect.position - global_position, tower_l2_rect.size)
	draw_rect(Rect2(l2.position + Vector2(0, 5), l2.size), Color(0, 0, 0, 0.55))
	draw_rect(l2, COL_FLOOR_2)
	draw_rect(l2, COL_FLOOR_2_EDGE, false, 2.0)
	draw_string(ThemeDB.fallback_font, l2.position + l2.size * 0.5 + Vector2(-20, 4),
		"TORRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, COL_FLOOR_2_EDGE)

	var l3 := Rect2(tower_l3_rect.position - global_position, tower_l3_rect.size)
	draw_rect(Rect2(l3.position + Vector2(0, 7), l3.size), Color(0, 0, 0, 0.65))
	draw_rect(l3, COL_TOWER)
	draw_rect(l3, COL_TOWER_EDGE, false, 2.5)
	var alm_y: float = l3.position.y - 6.0
	for i in 5:
		var alm_x: float = l3.position.x + 4.0 + float(i) * 13.0
		draw_rect(Rect2(Vector2(alm_x, alm_y), Vector2(7.0, 6.0)), COL_TOWER)
		draw_rect(Rect2(Vector2(alm_x, alm_y), Vector2(7.0, 6.0)), COL_TOWER_EDGE, false, 1.0)
	draw_rect(Rect2(l3.position, Vector2(l3.size.x, 4.0)),
		COL_TOWER_EDGE * Color(0.7, 0.85, 1.0, 1.0))


func _draw_slot(slot: Slot) -> void:
	var rl := Rect2(slot.pos - global_position - slot.size * 0.5, slot.size)
	if slot.built:
		draw_rect(rl, slot.color * Color(0.25, 0.25, 0.25, 0.95))
		draw_rect(rl, slot.color, false, 1.5)
		draw_rect(Rect2(rl.position, Vector2(rl.size.x, 6.0)), slot.color)
		draw_string(ThemeDB.fallback_font,
			rl.position + Vector2(rl.size.x * 0.5 - 22, 18),
			slot.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, slot.color * Color(1.4, 1.4, 1.4))
		if slot.hp < slot.max_hp:
			var bw := rl.size.x - 6.0
			var bx := rl.position.x + 3.0
			var by := rl.position.y + rl.size.y - 5.0
			draw_rect(Rect2(Vector2(bx, by), Vector2(bw, 3)), Color(0.10, 0.0, 0.0, 0.85))
			draw_rect(Rect2(Vector2(bx, by),
				Vector2(bw * float(slot.hp) / float(slot.max_hp), 3)),
				Color(0.95, 0.20, 0.15))
	else:
		var dc := slot.color * Color(1, 1, 1, 0.45)
		_draw_dashed_rect(rl, dc, 4.0, 3.0)
		draw_string(ThemeDB.fallback_font,
			rl.position + Vector2(rl.size.x * 0.5 - 18, 16),
			slot.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, dc)
		draw_string(ThemeDB.fallback_font,
			rl.position + Vector2(rl.size.x * 0.5 - 14, 28),
			"[20 ⚙]", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, dc)


func _draw_dashed_rect(r: Rect2, color: Color, dash: float, gap: float) -> void:
	var segs := [
		[r.position,                            r.position + Vector2(r.size.x, 0)],
		[r.position + Vector2(r.size.x, 0),     r.position + r.size],
		[r.position + r.size,                   r.position + Vector2(0, r.size.y)],
		[r.position + Vector2(0, r.size.y),     r.position],
	]
	for seg in segs:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var dist: float = a.distance_to(b)
		var dir: Vector2 = (b - a).normalized()
		var t: float = 0.0
		while t < dist:
			draw_line(a + dir * t, a + dir * minf(t + dash, dist), color, 1.2)
			t += dash + gap


func _draw_core(c: Vector2) -> void:
	var pulse: float = 0.85 + 0.15 * sin(_pulse_t * 3.0)
	var oct: PackedVector2Array = PackedVector2Array()
	for i in 8:
		var a: float = deg_to_rad(22.5 + float(i) * 45.0)
		oct.append(c + Vector2(cos(a), sin(a)) * 28.0)
	draw_colored_polygon(oct, Color(0.04, 0.10, 0.16))
	draw_polyline(oct + PackedVector2Array([oct[0]]), COL_CORE_OUTER, 2.0)
	draw_circle(c, CORE_R, COL_CORE_OUTER * Color(pulse, pulse, pulse, 1.0))
	draw_circle(c, CORE_R * 0.55, COL_CORE_INNER * Color(1, 1, 1, 0.85))
	draw_circle(c, CORE_R * 0.25, Color(1, 1, 1, 0.85))
	var ring_r := CORE_R + 6.0
	for i in 16:
		var a0: float = (TAU / 16.0) * float(i) + _pulse_t * 0.6
		var a1: float = a0 + (TAU / 32.0)
		draw_arc(c, ring_r, a0, a1, 6, COL_CORE_OUTER * Color(1, 1, 1, 0.7), 1.0)


func _draw_antennas() -> void:
	var pr: float = 0.5 + 0.5 * sin(_pulse_t * 5.0)
	var tt: Vector2 = tower_l3_rect.position - global_position \
		+ Vector2(tower_l3_rect.size.x * 0.5, -6.0)
	draw_line(tt, tt + Vector2(0, -20), Color(0.36, 0.41, 0.47), 1.5)
	draw_circle(tt + Vector2(0, -22), 2.5, Color(1.0, 0.22, 0.22, pr))


func _draw_bunker_details(c: Vector2) -> void:
	var sand    := Color(0.45, 0.38, 0.24)
	var sand_d  := Color(0.32, 0.26, 0.16)
	var metal   := Color(0.30, 0.28, 0.24)
	var metal_hi := Color(0.50, 0.46, 0.38)
	var gp      := global_position

	# Sandbags at each gate
	for k in door_centers:
		var g: Vector2 = door_centers[k] - gp
		var is_n: bool = (k == "N")
		for s: float in [-1.0, 1.0]:
			for i in 3:
				var off: float = 34.0 + float(i) * 10.0
				var bp: Vector2 = g + (Vector2(s * off, 0.0) if is_n else Vector2(0.0, s * off))
				var wobble: Vector2 = Vector2(s * 3.0, 0.0) if is_n else Vector2(0.0, s * 3.0)
				draw_circle(bp,                  5.5, sand_d)
				draw_circle(bp + Vector2(0, -6), 5.0, sand)
				draw_circle(bp + wobble,         4.5, sand_d)

	# Generator (right side of octagon)
	var gc := c + Vector2(50.0, 28.0)
	draw_rect(Rect2(gc + Vector2(-16, -10), Vector2(32, 22)), Color(0.18, 0.20, 0.16))
	draw_rect(Rect2(gc + Vector2(-16, -10), Vector2(32, 22)), metal_hi, false, 1.5)
	for vi in 4:
		draw_line(gc + Vector2(-12, -6 + vi * 5), gc + Vector2(4, -6 + vi * 5), metal, 0.8)
	draw_rect(Rect2(gc + Vector2(4, -8), Vector2(10, 18)), Color(0.22, 0.24, 0.20))
	draw_circle(gc + Vector2(9, -3), 2.5,
		Color(0.0, 0.9, 0.3, 0.8 + 0.2 * sin(_pulse_t * 4.2)))
	draw_circle(gc + Vector2(9, 4), 1.8, Color(0.9, 0.5, 0.0, 0.75))
	draw_line(gc + Vector2(-8, -10), gc + Vector2(-8, -20), metal, 3.5)
	draw_line(gc + Vector2(-2, -10), gc + Vector2(-2, -18), metal, 3.5)

	# Panel marks at arm midpoints
	for k in arm_polygons:
		var poly: Array = arm_polygons[k]
		var mp := Vector2.ZERO
		for v in poly:
			mp += v as Vector2
		mp = mp / float(poly.size()) - gp
		draw_arc(mp, 6.0, 0, TAU, 10, metal * Color(1, 1, 1, 0.5), 1.0)
		draw_line(mp + Vector2(-8, 0), mp + Vector2(8, 0), metal * Color(1, 1, 1, 0.4), 0.8)
		draw_line(mp + Vector2(0, -8), mp + Vector2(0, 8), metal * Color(1, 1, 1, 0.4), 0.8)


func _draw_wall_damage() -> void:
	for fw in _fort_walls:
		if not is_instance_valid(fw):
			continue
		var fw_node := fw as FortWall
		if fw_node.hp >= fw_node.max_hp:
			continue
		var pct := float(fw_node.hp) / float(fw_node.max_hp)
		if pct > 0.80:
			continue
		var intensity := 1.0 - pct
		var cc := Color(COL_CRACK.r, COL_CRACK.g, COL_CRACK.b, COL_CRACK.a * intensity)

		var cs_node: CollisionShape2D = null
		for child in fw_node.get_children():
			if child is CollisionShape2D:
				cs_node = child as CollisionShape2D
				break
		if cs_node == null:
			continue
		var rs := cs_node.shape as RectangleShape2D
		if rs == null:
			continue

		# fw_node.position is in Fortress local space — same space as _draw()
		var half := rs.size * 0.5
		var r    := Rect2(fw_node.position - half, rs.size)

		if pct <= 0.0:
			draw_line(r.position, r.position + r.size, cc, 3.0)
			draw_line(r.position + Vector2(r.size.x, 0),
				r.position + Vector2(0, r.size.y), cc, 3.0)
		else:
			var n_cracks := int((1.0 - pct) * 5.0) + 1
			for i in n_cracks:
				var t0 := float(i) / float(n_cracks)
				var t1 := minf(t0 + 0.25, 1.0)
				draw_line(
					Vector2(r.position.x + r.size.x * t0, r.position.y),
					Vector2(r.position.x + r.size.x * t1, r.position.y + r.size.y),
					cc, 1.5)


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

func get_stair_at(pos: Vector2) -> Variant:
	for sz in stair_zones:
		if (sz["rect"] as Rect2).has_point(pos):
			return sz
	return null


func get_elevation_at(pos: Vector2) -> int:
	if (tower_l3_rect as Rect2).has_point(pos):
		return 3
	if (tower_l2_rect as Rect2).has_point(pos):
		return 2
	if (south_wall_rect as Rect2).has_point(pos):
		return 1
	return 0


func nearest_door_pos(from_pos: Vector2) -> Vector2:
	var best_d   := INF
	var best_pos := door_centers["N"] as Vector2
	for k in door_centers:
		var d: float = from_pos.distance_to(door_centers[k])
		if d < best_d:
			best_d   = d
			best_pos = door_centers[k]
	return best_pos


func is_inside_hex(pos: Vector2) -> bool:
	return pos.distance_to(hex_center) < (OCT_RADIUS * 0.85)


func get_slot_by_type(stype: int) -> Slot:
	for slot in slots:
		if slot.stype == stype:
			return slot
	return null


func has_station(stype: int) -> bool:
	var slot := get_slot_by_type(stype)
	return slot != null and slot.built


func get_slot_at(pos: Vector2) -> Slot:
	for slot in slots:
		if Rect2(slot.pos - slot.size * 0.5, slot.size).has_point(pos):
			return slot
	return null


func build_station(stype: int) -> bool:
	var slot := get_slot_by_type(stype)
	if slot == null or slot.built:
		return false
	slot.built = true
	slot.hp    = slot.max_hp
	queue_redraw()
	return true


func get_core_pos() -> Vector2:
	return hex_center


func get_door_centers() -> Dictionary:
	return door_centers


func get_level_bounds(level: int, _pos: Vector2) -> Rect2:
	match level:
		1: return south_wall_rect
		2: return tower_l2_rect
		3: return tower_l3_rect
		_: return Rect2()


func get_damageable_walls() -> Array:
	return _fort_walls

extends "res://scripts/npc_soldier.gd"

const TURRET_SCENE = preload("res://scenes/turret.tscn")
const WALL_SCENE   = preload("res://scenes/wall.tscn")

const SPEED        := 115.0
const BUILD_RATE   := 5.0
const REPAIR_RANGE := 50.0
const REPAIR_RATE  := 1.0
const REPAIR_AMT   := 35
const FOLLOW_DIST  := 130.0
const BUILD_RADIUS := 110.0

const FLAME_RANGE  := 130.0
const FLAME_CONE   := PI / 2.2
const FLAME_DMG    := 5
const FLAME_RATE   := 0.18

var bullet_container: Node2D
var enemies_node:     Node2D
var walls_node:       Node2D

var build_phase_active:  bool    = false
var current_threat_dir:  Vector2 = Vector2.ZERO

var _build_cd:     float   = 1.5
var _repair_cd:    float   = 0.0
var _flame_cd:     float   = 0.0
var _flame_active: bool    = false
var _flame_dir:    Vector2 = Vector2.RIGHT
var _build_pulse:  float   = 0.0
var _build_target: Vector2 = Vector2.ZERO
var _t:            float   = 0.0

func _ready() -> void:
	role        = "ENGINEER"
	max_hp      = 90
	hp          = max_hp
	_sprite_tex = "res://assets/sprites/npc_engineer.png"
	super._ready()

func _act(delta: float) -> void:
	_t           += delta
	_build_cd    -= delta
	_repair_cd   -= delta
	_flame_cd    -= delta
	_build_pulse  = maxf(_build_pulse - delta * 1.5, 0.0)

	if build_phase_active:
		_flame_active = false
		_build_phase_logic()
	else:
		_combat_logic()
	queue_redraw()

func _build_phase_logic() -> void:
	# Roam around base perimeter and build structures
	if _build_target == Vector2.ZERO \
			or global_position.distance_to(_build_target) < 35.0:
		var angle := randf() * TAU
		_build_target = base_pos + Vector2(cos(angle), sin(angle)) * BUILD_RADIUS

	var to_t := _build_target - global_position
	if to_t.length() > 30.0:
		velocity = to_t.normalized() * SPEED
	else:
		velocity = Vector2.ZERO
		if _build_cd <= 0.0:
			var build_dir := (_build_target - base_pos).normalized()
			_try_build(build_dir)
			_build_target = Vector2.ZERO

func _try_build(build_dir: Vector2) -> void:
	if not is_instance_valid(walls_node):
		return
	var place_pos := global_position + build_dir * 20.0
	place_pos = Vector2(
		round(place_pos.x / 40.0) * 40.0,
		round(place_pos.y / 20.0) * 20.0)
	if _has_structure_near(place_pos, 30.0):
		_build_cd = 1.0
		return
	if randf() < 0.65:
		var w := WALL_SCENE.instantiate()
		w.position = place_pos
		walls_node.add_child(w)
	else:
		var t := TURRET_SCENE.instantiate()
		t.position         = place_pos
		t.bullet_container = bullet_container
		t.enemies_node     = enemies_node
		walls_node.add_child(t)
	_build_cd    = BUILD_RATE
	_build_pulse = 1.0

func _has_structure_near(pos: Vector2, radius: float) -> bool:
	for s in walls_node.get_children():
		if is_instance_valid(s) and s.global_position.distance_to(pos) < radius:
			return true
	return false

func _combat_logic() -> void:
	# 1) Try to repair damaged walls first
	var repair_target := _find_repair_target()
	if is_instance_valid(repair_target):
		_flame_active = false
		var to_t := repair_target.global_position - global_position
		if to_t.length() > REPAIR_RANGE:
			velocity = to_t.normalized() * SPEED
		else:
			velocity = Vector2.ZERO
			if _repair_cd <= 0.0:
				_repair(repair_target)
		return

	# 2) Flamethrower if enemies nearby
	var threat := _find_nearest_enemy()
	if is_instance_valid(threat):
		var to_e := threat.global_position - global_position
		var dist  := to_e.length()
		_flame_dir    = to_e.normalized()
		_flame_active = dist <= FLAME_RANGE * 1.15
		if dist > FLAME_RANGE * 0.55:
			velocity = _flame_dir * SPEED
		else:
			velocity = Vector2.ZERO
		if _flame_active and _flame_cd <= 0.0:
			_apply_flame()
		return

	# 3) Idle near player
	_flame_active = false
	if is_instance_valid(player):
		var to_p := player.global_position - global_position
		if to_p.length() > FOLLOW_DIST:
			velocity = to_p.normalized() * SPEED * 0.55
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

func _find_nearest_enemy() -> Node2D:
	if not is_instance_valid(enemies_node):
		return null
	var best: Node2D = null
	var best_d := FLAME_RANGE * 1.5
	for e in enemies_node.get_children():
		if not is_instance_valid(e) or not e.has_method("take_damage"):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best   = e
	return best

func _apply_flame() -> void:
	if not is_instance_valid(enemies_node):
		return
	var half_cone := FLAME_CONE * 0.5
	for e in enemies_node.get_children():
		if not is_instance_valid(e) or not e.has_method("take_damage"):
			continue
		var to_e: Vector2 = e.global_position - global_position
		if to_e.length() > FLAME_RANGE:
			continue
		var angle_diff: float = abs(to_e.normalized().angle_to(_flame_dir))
		if angle_diff <= half_cone:
			e.take_damage(FLAME_DMG)
	_flame_cd = FLAME_RATE

func _find_repair_target() -> Node2D:
	if not is_instance_valid(walls_node):
		return null
	var best: Node2D = null
	var worst_pct := 0.70
	for s in walls_node.get_children():
		if not is_instance_valid(s):
			continue
		var hp_v:  Variant = s.get("hp")
		var max_v: Variant = s.get("max_hp")
		if hp_v == null or max_v == null:
			continue
		var pct := float(int(hp_v)) / float(int(max_v))
		if pct < worst_pct:
			worst_pct = pct
			best      = s
	return best

func _repair(target: Node) -> void:
	target.hp = mini(int(target.hp) + REPAIR_AMT, int(target.max_hp))
	if target.has_method("queue_redraw"):
		target.queue_redraw()
	_repair_cd   = REPAIR_RATE
	_build_pulse = 1.0

func _draw() -> void:
	super._draw()
	if down:
		return

	# Flamethrower beam
	if _flame_active:
		var a_base := _flame_dir.angle()
		var half   := FLAME_CONE * 0.5
		for j in 10:
			var a    := a_base + randf_range(-half, half)
			var r    := FLAME_RANGE * randf_range(0.25, 1.0)
			var pct  := r / FLAME_RANGE
			var g    := randf_range(0.2, 0.55) * (1.0 - pct * 0.6)
			var alph := randf_range(0.5, 0.85) * (1.0 - pct * 0.45)
			draw_line(
				_flame_dir * 10.0,
				Vector2(cos(a), sin(a)) * r,
				Color(1.0, g, 0.0, alph), 2.5)
		# Core nozzle glow
		draw_circle(_flame_dir * 12.0, 5.0, Color(1.0, 0.75, 0.1, 0.9))

	# Build/repair pulse
	elif _build_pulse > 0.0:
		var col := Color(1.0, 0.65, 0.20, _build_pulse * 0.85)
		draw_arc(Vector2.ZERO, RADIUS + 5.0, 0, TAU, 28, col, 2.0)
		draw_line(Vector2(8, -8),   Vector2(16, -16), col, 1.5)
		draw_line(Vector2(8,  8),   Vector2(16,  16), col, 1.5)
		draw_line(Vector2(-8, -8),  Vector2(-16, -16), col, 1.5)

extends "res://scripts/npc_soldier.gd"

const BULLET_SCENE = preload("res://scenes/bullet.tscn")

const SPEED          := 140.0
const HEAL_RANGE     := 55.0
const HEAL_RATE      := 1.2
const HEAL_AMOUNT    := 18
const HEAL_THRESHOLD := 0.60
const REVIVE_HP      := 60
const FOLLOW_DIST    := 110.0

const SHOOT_RANGE    := 220.0
const SHOOT_RATE     := 0.85

var bullet_container: Node2D
var enemies_node:     Node2D

var _heal_cd:   float   = 0.0
var _shoot_cd:  float   = 0.0
var _heal_pulse: float  = 0.0
var _aim_dir:   Vector2 = Vector2.RIGHT

func _ready() -> void:
	role        = "MEDIC"
	max_hp      = 80
	hp          = max_hp
	_sprite_tex = "res://assets/sprites/npc_medic.png"
	super._ready()

func _act(delta: float) -> void:
	_heal_cd    -= delta
	_shoot_cd   -= delta
	_heal_pulse  = maxf(_heal_pulse - delta * 2.0, 0.0)

	var heal_target := _find_heal_target()
	if is_instance_valid(heal_target):
		# Priority 1: move to heal target
		var to_t := heal_target.global_position - global_position
		if to_t.length() > HEAL_RANGE:
			velocity = to_t.normalized() * SPEED
		else:
			velocity = Vector2.ZERO
			if _heal_cd <= 0.0:
				_apply_heal(heal_target)
	else:
		# Priority 2: shoot nearby enemies (pistol)
		var threat := _find_shoot_target()
		if is_instance_valid(threat):
			var to_e := threat.global_position - global_position
			_aim_dir = to_e.normalized()
			if to_e.length() > SHOOT_RANGE * 0.6:
				velocity = _aim_dir * SPEED * 0.7
			else:
				velocity = Vector2.ZERO
			if _shoot_cd <= 0.0:
				_shoot()
		else:
			# Idle: volver al centro del hex para poder alcanzar a cualquiera rápido
			var idle_target: Vector2
			if base_pos != Vector2.ZERO:
				idle_target = base_pos
			elif is_instance_valid(player):
				idle_target = player.global_position
			else:
				velocity = Vector2.ZERO
				queue_redraw()
				return
			var to_idle := idle_target - global_position
			if to_idle.length() > 80.0:
				velocity = to_idle.normalized() * SPEED * 0.55
			else:
				velocity = Vector2.ZERO
	queue_redraw()

func _find_heal_target() -> Node2D:
	# 0a) Downed player — absolute top priority (revival timer ticking)
	if is_instance_valid(player) and player.hp <= 0:
		return player
	# 0b) Player critically low — second priority
	if is_instance_valid(player):
		if float(player.hp) < float(player.max_hp) * 0.28:
			return player
	# 1) Downed NPC
	for a in get_tree().get_nodes_in_group("allies"):
		if a == self:
			continue
		if is_instance_valid(a) and a.get("down") == true:
			return a
	# 2) Player below threshold
	if is_instance_valid(player):
		if float(player.hp) < float(player.max_hp) * HEAL_THRESHOLD:
			return player
	# 3) Injured NPC
	for a in get_tree().get_nodes_in_group("allies"):
		if a == self or not is_instance_valid(a):
			continue
		if a.get("down") == true:
			continue
		if float(a.hp) < float(a.max_hp) * HEAL_THRESHOLD:
			return a
	return null

func _find_shoot_target() -> Node2D:
	if not is_instance_valid(enemies_node):
		return null
	var best: Node2D = null
	var best_d := SHOOT_RANGE * SHOOT_RANGE
	for e in enemies_node.get_children():
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best   = e
	return best

func _apply_heal(target: Node) -> void:
	if target.get("down") == true:
		if target.has_method("revive"):
			target.revive(REVIVE_HP)
	else:
		var new_hp := mini(int(target.hp) + HEAL_AMOUNT, int(target.max_hp))
		target.hp = new_hp
		if target.has_signal("health_changed"):
			target.health_changed.emit(new_hp)
		if target.has_method("queue_redraw"):
			target.queue_redraw()
		# Cure infection
		if target.get("infected") == true:
			target.set("infected", false)
			if target.has_signal("infection_changed"):
				target.infection_changed.emit(false)
	_heal_cd    = HEAL_RATE
	_heal_pulse = 1.0

func _shoot() -> void:
	if not is_instance_valid(bullet_container):
		return
	var b := BULLET_SCENE.instantiate()
	b.global_position = global_position + _aim_dir * 16.0
	b.direction       = _aim_dir
	b.bcolor          = Color(0.30, 1.0, 0.55)
	b.bradius         = 4.0
	bullet_container.call_deferred("add_child", b)
	_shoot_cd = SHOOT_RATE

func _draw() -> void:
	super._draw()
	if down:
		return
	# Heal pulse ring
	if _heal_pulse > 0.0:
		var r := RADIUS + 6.0 + (1.0 - _heal_pulse) * 10.0
		draw_arc(Vector2.ZERO, r, 0, TAU, 32,
			Color(0.30, 1.0, 0.55, _heal_pulse * 0.7), 2.5)
	# Pistol barrel
	else:
		draw_line(Vector2(2, 0), _aim_dir * 14.0,
			Color(0.35, 0.85, 0.55), 3.0)

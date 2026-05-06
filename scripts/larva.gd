extends CharacterBody2D

signal died(larva: Node)

const DAMAGE_INTERVAL = 0.5

var max_hp:       int   = 10
var melee_damage: int   = 5
var body_color:   Color = Color(0.85, 0.1, 0.1)
var body_radius:  float = 12.0

var speed:            float   = 75.0
var hp:               int     = -1
var player:           Node2D
var base_pos:         Vector2 = Vector2.ZERO
var fortress:         Node2D
var bullet_container: Node2D
var _dmg_cd:          float   = 0.0
var _wall_dmg_cd:     float   = 0.0
var _is_aerial:       bool    = false
var _current_target:  Vector2 = Vector2.ZERO

func _ready() -> void:
	if hp < 0:
		hp = max_hp
	collision_layer = 2
	collision_mask  = 9
	queue_redraw()

func _draw() -> void:
	# Cuerpo procedural
	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_arc(Vector2.ZERO, body_radius, 0, TAU, 24, body_color.lightened(0.4), 2.0)
	# HP bar
	if hp >= 0 and hp < max_hp:
		var bw := body_radius * 2.4
		var bh := 3.5
		var bx := -bw * 0.5
		var by := -(body_radius + 7.0)
		draw_rect(Rect2(bx, by, bw, bh), Color(0.1, 0.0, 0.0, 0.85))
		draw_rect(Rect2(bx, by, bw * float(hp) / float(max_hp), bh), Color(1.0, 0.15, 0.1))

func _update_target() -> void:
	if is_instance_valid(player) and \
			global_position.distance_to(player.global_position) < 320.0:
		_current_target = player.global_position
		return
	if not is_instance_valid(fortress):
		_current_target = base_pos
		return
	if fortress.is_inside_hex(global_position):
		_current_target = base_pos
		return
	_current_target = fortress.nearest_door_pos(global_position)


func _physics_process(delta: float) -> void:
	_update_target()
	velocity = (_current_target - global_position).normalized() * speed
	move_and_slide()
	_dmg_cd      -= delta
	_wall_dmg_cd -= delta

	if _wall_dmg_cd <= 0.0:
		for i in get_slide_collision_count():
			var col  := get_slide_collision(i)
			var body := col.get_collider()
			if is_instance_valid(body) and (body.collision_layer & 8) and body.has_method("take_damage"):
				body.take_damage(melee_damage)
				_wall_dmg_cd = DAMAGE_INTERVAL
				break

	# Daño por proximidad: jugador o aliados (NPCs) — quien esté primero en rango
	if _dmg_cd <= 0.0:
		_try_melee_proximity()

# ─────────────────────────────────────────────────────────────────────────────
# CAMBIO 3 — Las larvas ahora también atacan a los NPCs aliados.
# Prioriza al jugador si está en rango, después a cualquier ally cercano.
# ─────────────────────────────────────────────────────────────────────────────
func _try_melee_proximity() -> void:
	# 1) Jugador — terrestres no atacan si está elevado
	if is_instance_valid(player):
		var p_level := 0
		if player.has_method("get_elevation_level"):
			p_level = player.get_elevation_level()
		if (p_level == 0 or _is_aerial) \
				and global_position.distance_to(player.global_position) < (body_radius + 16.0):
			player.take_damage(melee_damage)
			_dmg_cd = DAMAGE_INTERVAL
			if not player.get("serum") and not player.get("infected") and randf() < 0.45:
				player.set("infected", true)
				player.set("_infect_tick", 2.0)
				if player.has_signal("infection_changed"):
					player.infection_changed.emit(true)
			return
	# 2) Aliados (NPCs) en grupo "allies"
	for ally in get_tree().get_nodes_in_group("allies"):
		if not is_instance_valid(ally):
			continue
		if not ally.has_method("take_damage"):
			continue
		# Saltar si está incapacitado (down): se ignoran como objetivos
		if ally.get("down") == true:
			continue
		if global_position.distance_to(ally.global_position) < (body_radius + 16.0):
			ally.take_damage(melee_damage)
			_dmg_cd = DAMAGE_INTERVAL
			return

func take_damage(amount: int) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0:
		died.emit(self)
		queue_free()

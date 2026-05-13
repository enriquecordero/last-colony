extends CharacterBody2D

signal died(larva: Node)

const DAMAGE_INTERVAL = 0.5

var max_hp:       int   = 70
var melee_damage: int   = 5
var body_color:   Color = Color(0.85, 0.1, 0.1)
var body_radius:  float = 12.0

var speed:            float   = 35.0
var hp:               int     = -1
var player:           Node2D
var base_pos:         Vector2 = Vector2.ZERO
var fortress:         Node2D
var bullet_container: Node2D
var _dmg_cd:          float   = 0.0
var _wall_dmg_cd:     float   = 0.0
var _is_aerial:       bool    = false
var _current_target:  Vector2 = Vector2.ZERO

var _sprite_tex:   String   = ""
var _sprite_scale: float    = 0.60
var _sprite:       Sprite2D = null
var _draw_dir:     Vector2  = Vector2.RIGHT

var _stuck_cd:      float   = 0.0
var _stuck_check_t: float   = 0.0
var _last_check_pos: Vector2 = Vector2.ZERO
var _stuck_offset:  Vector2 = Vector2.ZERO

func _ready() -> void:
	if hp < 0:
		hp = max_hp
	add_to_group("enemies")
	collision_layer = 2
	collision_mask  = 9
	if not _sprite_tex.is_empty():
		_sprite                = Sprite2D.new()
		_sprite.texture        = load(_sprite_tex)
		_sprite.region_enabled = true
		_sprite.region_rect    = Rect2(0, 0, 64, 64)
		_sprite.scale          = Vector2(_sprite_scale, _sprite_scale)
		add_child(_sprite)
	queue_redraw()

func _draw() -> void:
	if _sprite == null:
		_draw_body()
	if hp >= 0 and hp < max_hp:
		var bw := body_radius * 2.4
		var bh := 3.5
		var bx := -bw * 0.5
		var by := -(body_radius + 7.0)
		draw_rect(Rect2(bx, by, bw, bh), Color(0.1, 0.0, 0.0, 0.85))
		draw_rect(Rect2(bx, by, bw * float(hp) / float(max_hp), bh), Color(1.0, 0.15, 0.1))

func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	draw_circle(d * 1.5 + Vector2(0, 2.5), r * 1.0, Color(0, 0, 0, 0.25))

	draw_circle(-d * r * 0.50, r * 0.76, c.darkened(0.22))
	draw_circle(Vector2.ZERO,   r * 0.86, c)
	draw_circle(d  * r * 0.72, r * 0.60, c.lightened(0.10))

	draw_line(-d * r * 0.18 - p * r * 0.62, -d * r * 0.18 + p * r * 0.62, c.darkened(0.50), 1.5)
	draw_line( d * r * 0.22 - p * r * 0.50,  d * r * 0.22 + p * r * 0.50, c.darkened(0.50), 1.5)

	for i in 3:
		var base := d * r * ((i - 1.0) * 0.42)
		for s: float in [-1.0, 1.0]:
			var knee := base + p * s * r * 0.55
			var tip  := knee + p * s * r * 0.45 - d * r * 0.20
			draw_line(base, knee, c.darkened(0.10), 1.8)
			draw_line(knee, tip,  c.darkened(0.30), 1.4)

	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.72 + p * s * r * 0.27
		draw_circle(ep, 2.5, Color(1.0, 0.90, 0.05))
		draw_circle(ep, 1.1, Color(0.05, 0.0,  0.0))

	for s: float in [-1.0, 1.0]:
		draw_line(d * r * 0.95 + p * s * r * 0.18,
		          d * r * 1.28 + p * s * r * 0.40,
		          c.lightened(0.30), 2.2)

	draw_arc(Vector2.ZERO, r, 0, TAU, 24, c.lightened(0.35), 1.2)

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
	# Anti-stuck: if barely moved in 0.6s, inject a random lateral push
	_stuck_check_t += delta
	if _stuck_check_t >= 0.6:
		_stuck_check_t = 0.0
		if global_position.distance_to(_last_check_pos) < 8.0:
			var perp := Vector2(-(_current_target - global_position).normalized().y,
								 (_current_target - global_position).normalized().x)
			_stuck_offset = perp * randf_range(0.4, 0.9) * speed
			_stuck_cd     = 0.35
		_last_check_pos = global_position
	if _stuck_cd > 0.0:
		_stuck_cd -= delta
	else:
		_stuck_offset = _stuck_offset.lerp(Vector2.ZERO, delta * 6.0)
	var dir: Vector2 = (_current_target - global_position).normalized()
	velocity = (dir * speed + _stuck_offset)
	move_and_slide()
	if velocity.length_squared() > 1.0:
		_draw_dir = velocity.normalized()
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
	modulate = Color(1.8, 0.25, 0.25)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.10)
	queue_redraw()
	if hp <= 0:
		died.emit(self)
		queue_free()

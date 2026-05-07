extends "res://scripts/larva.gd"

const EnemyProj = preload("res://scripts/enemy_projectile.gd")
const AcidPool  = preload("res://scripts/acid_pool.gd")
const SHOOT_RANGE = 210.0
const SHOOT_RATE  = 2.2

var _shoot_cd: float = 0.0

func _ready() -> void:
	max_hp       = 60
	melee_damage = 6
	body_color   = Color(0.62, 0.12, 0.78)
	body_radius  = 11.0
	speed        = 62.0
	super._ready()
	_shoot_cd = randf_range(0.8, 2.5)

func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	draw_circle(Vector2(2, 3), r * 1.0, Color(0, 0, 0, 0.25))

	draw_circle(-d * r * 0.42, r * 0.74, c.darkened(0.22))
	draw_circle(Vector2.ZERO,   r * 0.82, c)
	draw_circle(d  * r * 0.62,  r * 0.70, c.lightened(0.08))
	draw_circle(d  * r * 0.95,  r * 0.52, c.darkened(0.08))

	# Glowing acid sac in throat
	var sac := d * r * 0.42
	draw_circle(sac, r * 0.30, Color(0.10, 0.65, 0.10, 0.55))
	draw_circle(sac, r * 0.18, Color(0.35, 1.00, 0.18, 0.90))
	draw_line(sac, d * r * 1.00, Color(0.25, 0.85, 0.12, 0.45), 2.2)

	for i in 2:
		var base := d * r * ((i - 0.5) * 0.45)
		for s: float in [-1.0, 1.0]:
			var knee := base + p * s * r * 0.60
			var tip  := knee + p * s * r * 0.38 - d * r * 0.15
			draw_line(base, knee, c.darkened(0.10), 2.0)
			draw_line(knee, tip,  c.darkened(0.28), 1.5)

	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.65 + p * s * r * 0.32
		draw_circle(ep, 2.4, Color(0.82, 0.22, 1.0))
		draw_circle(ep, 1.1, Color(0.05, 0.0,  0.08))

	draw_line(-d * r * 0.06 - p * r * 0.55, -d * r * 0.06 + p * r * 0.55,
	          c.darkened(0.45), 1.5)

	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.55, 1.0, 0.75))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, c.lightened(0.35), 1.2)

func _physics_process(delta: float) -> void:
	_update_target()

	var dist := global_position.distance_to(_current_target)
	if dist > SHOOT_RANGE:
		velocity = (_current_target - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if velocity.length_squared() > 1.0:
		_draw_dir = velocity.normalized()
	elif is_instance_valid(player):
		_draw_dir = (player.global_position - global_position).normalized()

	_dmg_cd      -= delta
	_wall_dmg_cd -= delta
	_shoot_cd    -= delta

	if _wall_dmg_cd <= 0.0:
		for i in get_slide_collision_count():
			var col  := get_slide_collision(i)
			var body := col.get_collider()
			if is_instance_valid(body) and (body.collision_layer & 8) and body.has_method("take_damage"):
				body.take_damage(melee_damage)
				_wall_dmg_cd = DAMAGE_INTERVAL
				break

	if _dmg_cd <= 0.0:
		_try_melee_proximity()

	# Disparo: los proyectiles SÍ alcanzan al jugador elevado
	if _shoot_cd <= 0.0 and is_instance_valid(bullet_container):
		var target := _current_target
		if is_instance_valid(player) \
				and global_position.distance_to(player.global_position) < SHOOT_RANGE * 1.2:
			target = player.global_position
		if global_position.distance_to(target) <= SHOOT_RANGE:
			_fire_at(target)
			_shoot_cd = SHOOT_RATE


func _fire_at(target_pos: Vector2) -> void:
	var p             := EnemyProj.new()
	p.global_position  = global_position
	p.direction        = (target_pos - global_position).normalized()
	bullet_container.call_deferred("add_child", p)
	var pool := AcidPool.new()
	pool.global_position = target_pos
	pool.player          = player
	bullet_container.call_deferred("add_child", pool)

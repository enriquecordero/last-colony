extends "res://scripts/larva.gd"

const EnemyProj   = preload("res://scripts/enemy_projectile.gd")
const SHOOT_RANGE = 210.0
const SHOOT_RATE  = 2.2

var _shoot_cd: float = 0.0

func _ready() -> void:
	max_hp       = 60
	melee_damage = 6
	body_color   = Color(0.62, 0.12, 0.78)
	body_radius  = 11.0
	speed        = 62.0
	_sprite_tex   = "res://assets/sprites/escupidor.png"
	_sprite_scale = 0.58
	super._ready()
	_shoot_cd = randf_range(0.8, 2.5)

func _draw() -> void:
	super._draw()

func _physics_process(delta: float) -> void:
	_update_target()

	var dist := global_position.distance_to(_current_target)
	if dist > SHOOT_RANGE:
		velocity = (_current_target - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

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

extends CharacterBody2D

const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const SPEED        = 110.0
const RANGE        = 280.0
const FIRE_RATE    = 1.0

var hp:               int     = 80
var max_hp:           int     = 80
var bullet_container: Node2D
var enemies_node:     Node2D
var _fire_cd:         float   = 0.0
var _target_dir:      Vector2 = Vector2.RIGHT

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 0
	queue_redraw()

func _physics_process(delta: float) -> void:
	_fire_cd -= delta
	var nearest := _find_nearest()
	if is_instance_valid(nearest):
		var dir := (nearest.global_position - global_position).normalized()
		_target_dir = dir
		velocity    = dir * SPEED
		queue_redraw()
		if _fire_cd <= 0.0:
			_shoot()
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _find_nearest() -> Node2D:
	if not is_instance_valid(enemies_node):
		return null
	var best:      Node2D = null
	var best_dist: float  = RANGE * RANGE
	for e in enemies_node.get_children():
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best      = e
	return best

func _shoot() -> void:
	if not is_instance_valid(bullet_container):
		return
	var b := BULLET_SCENE.instantiate()
	b.global_position = global_position
	b.direction       = _target_dir
	b.bcolor          = Color(0.35, 0.78, 1.0)
	b.bradius         = 6.0
	bullet_container.call_deferred("add_child", b)
	_fire_cd = FIRE_RATE

func take_damage(amount: int) -> void:
	hp -= amount
	queue_redraw()
	modulate = Color(1.0, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)
	if hp <= 0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 12, Color(0.18, 0.45, 0.70))
	draw_arc(Vector2.ZERO, 12, 0, TAU, 24, Color(0.42, 0.78, 1.0), 2.5)
	draw_circle(Vector2(3, 0), 5, Color(0.08, 0.28, 0.50))
	draw_circle(Vector2(5, 0), 2, Color(0.45, 0.88, 1.0))
	var barrel := _target_dir * 16.0
	draw_line(Vector2(2, 0), barrel, Color(0.52, 0.62, 0.72), 4.0)
	if hp < max_hp:
		var t := float(hp) / float(max_hp)
		draw_rect(Rect2(-12, -18, 24, 3), Color(0.1, 0.0, 0.0))
		draw_rect(Rect2(-12, -18, 24.0 * t, 3), Color(0.3, 0.62, 1.0))

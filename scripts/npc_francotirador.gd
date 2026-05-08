extends "res://scripts/npc_soldier.gd"

const BULLET_SCENE = preload("res://scenes/bullet.tscn")

const RANGE      := 680.0
const SPEED      := 85.0
const FIRE_RATE  := 2.6
const POST_DIST  := 50.0

var bullet_container: Node2D
var enemies_node:     Node2D
var _fire_cd: float   = randf_range(0.5, 2.0)
var _aim_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	role    = "SNIPER"
	max_hp  = 70
	hp      = max_hp
	super._ready()

func _act(delta: float) -> void:
	_fire_cd -= delta
	var threat := _find_threat()
	if is_instance_valid(threat):
		var to_t  := threat.global_position - global_position
		_aim_dir   = to_t.normalized()
		# Sniper stays at post — does NOT advance toward threat
		var idle_target := post_pos if post_pos != Vector2.ZERO else base_pos
		if idle_target != Vector2.ZERO:
			var to_idle := idle_target - global_position
			velocity = to_idle.normalized() * SPEED if to_idle.length() > POST_DIST else Vector2.ZERO
		else:
			velocity = Vector2.ZERO
		if _fire_cd <= 0.0 and to_t.length() <= RANGE:
			_shoot()
	else:
		var idle_target := post_pos if post_pos != Vector2.ZERO else base_pos
		if idle_target == Vector2.ZERO:
			velocity = Vector2.ZERO
		else:
			var to_idle := idle_target - global_position
			velocity = to_idle.normalized() * SPEED if to_idle.length() > POST_DIST else Vector2.ZERO
	queue_redraw()

func _find_threat() -> Node2D:
	if not is_instance_valid(enemies_node):
		return null
	var best: Node2D = null
	var best_d := RANGE * RANGE
	for e in enemies_node.get_children():
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best   = e
	return best

func _shoot() -> void:
	if not is_instance_valid(bullet_container):
		return
	var b := BULLET_SCENE.instantiate()
	b.global_position = global_position + _aim_dir * 20.0
	b.direction       = _aim_dir
	b.damage          = 90
	b.lifetime        = 3.8
	b.bcolor          = Color(0.82, 0.97, 1.0)
	b.bradius         = 4.0
	bullet_container.call_deferred("add_child", b)
	_fire_cd = FIRE_RATE

func _draw() -> void:
	super._draw()
	if not down:
		draw_line(Vector2(2, 0), _aim_dir * 26.0, Color(0.65, 0.82, 0.95), 3.0)
		draw_line(_aim_dir * 22.0, _aim_dir * 30.0, Color(0.82, 0.97, 1.0), 2.0)

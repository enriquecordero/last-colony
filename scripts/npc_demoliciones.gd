extends "res://scripts/npc_soldier.gd"

const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const MINE_SCENE   = preload("res://scenes/mine.tscn")

const SHOOT_RANGE       := 200.0
const SHOOT_RATE        := 0.50
const SPEED             := 125.0
const POST_DIST         := 55.0
const MINE_PLACE_RATE   := 24.0
const MAX_MINES         := 6
const GRENADE_RATE      := 5.5
const GRENADE_THROW_RNG := 320.0
const CLUSTER_RADIUS    := 90.0
const CLUSTER_MIN       := 5

var bullet_container: Node2D
var enemies_node:     Node2D
var walls_node:       Node2D
var main_ref:         Node = null
var _shoot_cd:   float   = randf_range(0.0, 0.5)
var _mine_cd:    float   = 4.0
var _gren_cd:    float   = 2.0
var _aim_dir:    Vector2 = Vector2.RIGHT
var _mines_laid: int     = 0

func _ready() -> void:
	role    = "DEMO"
	max_hp  = 115
	hp      = max_hp
	super._ready()

func _act(delta: float) -> void:
	_shoot_cd -= delta
	_mine_cd  -= delta
	_gren_cd  -= delta

	if _mine_cd <= 0.0 and _mines_laid < MAX_MINES:
		_place_mine()

	if _gren_cd <= 0.0:
		var cluster_pos: Vector2 = _find_cluster()
		if cluster_pos != Vector2.INF:
			_throw_grenade_at(cluster_pos)
			_gren_cd = GRENADE_RATE

	var threat := _find_threat()
	if is_instance_valid(threat):
		var to_t  := threat.global_position - global_position
		_aim_dir   = to_t.normalized()
		if to_t.length() > SHOOT_RANGE * 0.7:
			velocity = _aim_dir * SPEED
		else:
			velocity = Vector2.ZERO
		if _shoot_cd <= 0.0:
			_shoot()
	else:
		var idle_target: Vector2
		if post_pos != Vector2.ZERO:
			idle_target = post_pos
		elif is_instance_valid(player):
			idle_target = player.global_position
		else:
			velocity = Vector2.ZERO
			queue_redraw()
			return
		var to_idle := idle_target - global_position
		velocity = to_idle.normalized() * SPEED * 0.65 if to_idle.length() > POST_DIST else Vector2.ZERO
	queue_redraw()

func _find_threat() -> Node2D:
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

func _shoot() -> void:
	if not is_instance_valid(bullet_container):
		return
	for _i in 3:
		var b := BULLET_SCENE.instantiate()
		var spread_dir := _aim_dir.rotated(randf_range(deg_to_rad(-22.0), deg_to_rad(22.0)))
		b.global_position = global_position + spread_dir * 18.0
		b.direction       = spread_dir
		b.damage          = 22
		b.lifetime        = 0.40
		b.bcolor          = Color(1.0, 0.60, 0.10)
		b.bradius         = 5.0
		bullet_container.call_deferred("add_child", b)
	_shoot_cd = SHOOT_RATE

func _find_cluster() -> Vector2:
	if not is_instance_valid(enemies_node):
		return Vector2.INF
	var best_pos: Vector2 = Vector2.INF
	var best_count: int = CLUSTER_MIN - 1
	var children: Array = enemies_node.get_children()
	for anchor in children:
		if not is_instance_valid(anchor):
			continue
		var ap: Vector2 = anchor.global_position
		if global_position.distance_to(ap) > GRENADE_THROW_RNG:
			continue
		var count: int = 0
		for e in children:
			if is_instance_valid(e) and ap.distance_squared_to(e.global_position) <= CLUSTER_RADIUS * CLUSTER_RADIUS:
				count += 1
		if count > best_count:
			best_count = count
			best_pos   = ap
	return best_pos


func _throw_grenade_at(target_pos: Vector2) -> void:
	if main_ref == null or not is_instance_valid(main_ref):
		return
	if main_ref.has_method("throw_npc_grenade"):
		main_ref.throw_npc_grenade(global_position, target_pos)


func _place_mine() -> void:
	if not is_instance_valid(walls_node):
		return
	var dir := _aim_dir if _aim_dir.length() > 0.1 else Vector2.RIGHT
	var mine_pos := global_position + dir * 115.0
	var m := MINE_SCENE.instantiate()
	m.position = mine_pos
	walls_node.call_deferred("add_child", m)
	_mines_laid += 1
	_mine_cd = MINE_PLACE_RATE

func _draw() -> void:
	super._draw()
	if not down:
		draw_line(Vector2(2, 0), _aim_dir * 17.0, Color(1.0, 0.60, 0.10), 5.0)
		if _mines_laid < MAX_MINES:
			var f := ThemeDB.fallback_font
			draw_string(f, Vector2(-20, RADIUS + 14),
				"MINAS:%d" % (MAX_MINES - _mines_laid),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.65, 0.15, 0.9))

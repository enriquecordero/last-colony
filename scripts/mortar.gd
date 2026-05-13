extends StaticBody2D

const SHELL_RATE     := 4.5
const SHELL_RANGE    := 620.0
const SHELL_DAMAGE   := 80
const SHELL_RADIUS   := 110.0
const CLUSTER_R      := 80.0
const CLUSTER_MIN    := 4

var hp:               int   = 220
var max_hp:           int   = 220
var bullet_container: Node2D = null
var enemies_node:     Node2D = null
var main_ref:         Node   = null

var _fire_cd:  float = 1.5
var _aim_dir:  Vector2 = Vector2.UP
var _hit_t:    float = 0.0


func _ready() -> void:
	collision_layer = 32
	collision_mask  = 0
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size   = Vector2(34, 34)
	shape.shape = rect
	add_child(shape)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_fire_cd -= delta
	if _hit_t > 0.0:
		_hit_t = maxf(0.0, _hit_t - delta * 3.0)
		queue_redraw()
	if _fire_cd <= 0.0:
		var target_pos: Vector2 = _find_cluster()
		if target_pos != Vector2.INF:
			_fire(target_pos)
			_fire_cd = SHELL_RATE


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
		if global_position.distance_to(ap) > SHELL_RANGE:
			continue
		var count: int = 0
		for e in children:
			if is_instance_valid(e) and ap.distance_squared_to(e.global_position) <= CLUSTER_R * CLUSTER_R:
				count += 1
		if count > best_count:
			best_count = count
			best_pos   = ap
	return best_pos


func _fire(target_pos: Vector2) -> void:
	_aim_dir = (target_pos - global_position).normalized()
	queue_redraw()
	if main_ref == null or not is_instance_valid(main_ref):
		return
	if main_ref.has_method("spawn_mortar_shell"):
		main_ref.spawn_mortar_shell(global_position, target_pos, SHELL_DAMAGE, SHELL_RADIUS)
	SoundManager.play("shoot")


func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	_hit_t = 1.0
	modulate = Color(1.5, 0.5, 0.3)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.15)
	queue_redraw()
	if hp <= 0:
		queue_free()


func _draw() -> void:
	# Base plate
	draw_circle(Vector2(0, 4), 20.0, Color(0.20, 0.18, 0.18))
	draw_circle(Vector2.ZERO, 16.0, Color(0.38, 0.32, 0.28))
	draw_arc(Vector2.ZERO, 16.0, 0, TAU, 24, Color(0.65, 0.55, 0.40), 2.0)
	# Tube pointing at last aim (guard against zero aim dir → degenerate polygon)
	var dir: Vector2 = _aim_dir if _aim_dir.length_squared() > 0.01 else Vector2.UP
	var perp: Vector2 = Vector2(-dir.y, dir.x) * 4.0
	var base: Vector2 = -dir * 2.0
	var tip:  Vector2 = dir * 18.0
	draw_colored_polygon(PackedVector2Array([
		base + perp, base - perp, tip - perp, tip + perp
	]), Color(0.50, 0.40, 0.30))
	draw_circle(tip, 4.5, Color(0.20, 0.18, 0.18))
	# Hit flash
	if _hit_t > 0.0:
		draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.85, 0.40, _hit_t * 0.5))
	# HP bar
	if hp < max_hp:
		var bw := 30.0
		draw_rect(Rect2(-bw * 0.5, -24, bw, 3), Color(0.10, 0.0, 0.0, 0.85))
		draw_rect(Rect2(-bw * 0.5, -24, bw * float(hp) / float(max_hp), 3),
			Color(0.95, 0.75, 0.20))

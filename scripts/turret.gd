extends StaticBody2D

const BULLET_SCENE = preload("res://scenes/bullet.tscn")

const ELEV_RANGE_MULT := [1.0, 1.30, 1.60, 2.00]
const ELEV_DMG_MULT   := [1.0, 1.15, 1.30, 1.50]

const BASE_RANGE     := 230.0
const BASE_DAMAGE    := 25
const BASE_FIRE_RATE := 1.8

var hp:               int     = 150
var max_hp:           int     = 150
var bullet_container: Node2D
var enemies_node:     Node2D
var elevation_level:  int     = 0
var _fire_cd:         float   = 0.0
var _aim_dir:         Vector2 = Vector2.RIGHT


func _ready() -> void:
	collision_layer = 8
	collision_mask  = 0
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size   = Vector2(30, 30)
	shape.shape = rect
	add_child(shape)
	queue_redraw()


func _process(delta: float) -> void:
	_fire_cd -= delta
	var target := _find_target()
	if is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		if dir != _aim_dir:
			_aim_dir = dir
			queue_redraw()
		if _fire_cd <= 0.0:
			_shoot()


func _find_target() -> Node2D:
	if not is_instance_valid(enemies_node):
		return null
	var lvl  := clampi(elevation_level, 0, 3)
	var rng: float = BASE_RANGE * float(ELEV_RANGE_MULT[lvl])
	var rng2 := rng * rng
	var best: Node2D = null
	var best_d := rng2
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
	var lvl := clampi(elevation_level, 0, 3)
	var b   := BULLET_SCENE.instantiate()
	b.global_position = global_position + _aim_dir * 18.0
	b.direction       = _aim_dir
	b.bcolor          = Color(1.0, 0.85, 0.20)
	b.bradius         = 4.5
	if "damage" in b:
		b.damage = int(BASE_DAMAGE * ELEV_DMG_MULT[lvl])
	if "lifetime" in b:
		b.lifetime = float(b.lifetime) * ELEV_RANGE_MULT[lvl]
	bullet_container.call_deferred("add_child", b)
	SoundManager.play("shoot")
	_fire_cd = BASE_FIRE_RATE


func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	modulate = Color(1.5, 0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.15)
	queue_redraw()
	if hp <= 0:
		queue_free()


func _draw() -> void:
	var lvl := clampi(elevation_level, 0, 3)

	var body_col := Color(0.28, 0.30, 0.38)
	var edge_col := Color(0.48, 0.50, 0.62)
	if lvl == 1:
		body_col = Color(0.22, 0.40, 0.60)
		edge_col = Color(0.38, 0.60, 0.85)
	elif lvl == 2:
		body_col = Color(0.28, 0.55, 0.75)
		edge_col = Color(0.50, 0.78, 0.95)
	elif lvl == 3:
		body_col = Color(0.38, 0.72, 0.90)
		edge_col = Color(0.65, 0.92, 1.0)

	# Sombra elíptica si está elevada
	if lvl > 0:
		var rx := 18.0
		var ry := 4.5 + lvl * 0.5
		var cy := lvl * 4.0 + 12.0
		var pts := PackedVector2Array()
		for i in 14:
			var a := TAU * i / 14.0
			pts.append(Vector2(cos(a) * rx, cy + sin(a) * ry))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.5))

	draw_circle(Vector2(0, 4), 16, body_col.darkened(0.5))
	draw_circle(Vector2.ZERO, 13, body_col)
	draw_arc(Vector2.ZERO, 13, 0, TAU, 24, edge_col, 2.0)
	draw_circle(Vector2.ZERO, 4, body_col.darkened(0.4))

	# Cañón
	var perp := Vector2(-_aim_dir.y, _aim_dir.x) * 3.0
	draw_colored_polygon(PackedVector2Array([
		_aim_dir * 4.0 + perp,
		_aim_dir * 4.0 - perp,
		_aim_dir * 18.0 - perp,
		_aim_dir * 18.0 + perp,
	]), Color(0.55, 0.60, 0.65))

	if lvl > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-7, -19), "L%d" % lvl,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, edge_col)

	if hp < max_hp:
		var bw := 26.0
		draw_rect(Rect2(-bw * 0.5, -22, bw, 3), Color(0.10, 0.0, 0.0, 0.85))
		draw_rect(Rect2(-bw * 0.5, -22, bw * float(hp) / float(max_hp), 3),
			Color(0.95, 0.20, 0.15))

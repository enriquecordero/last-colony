extends "res://scripts/larva.gd"

const EXPLODE_RANGE := 65.0
const EXPLODE_DMG   := 65
const FUSE_TIME     := 0.45

var _fuse_t: float = 0.0
var _primed: bool  = false

func _ready() -> void:
	max_hp       = 55
	melee_damage = 0
	body_color   = Color(0.85, 0.42, 0.05)
	body_radius  = 13.0
	speed        = 52.0
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_instance_valid(player) and \
			global_position.distance_to(player.global_position) < EXPLODE_RANGE:
		_fuse_t += delta
		_primed  = true
		if _fuse_t >= FUSE_TIME:
			_explode()
	else:
		_fuse_t = maxf(_fuse_t - delta * 2.5, 0.0)
		_primed  = _fuse_t > 0.0

func _explode() -> void:
	if is_instance_valid(player) and \
			global_position.distance_to(player.global_position) < EXPLODE_RANGE * 1.2:
		player.take_damage(EXPLODE_DMG)
	for ally in get_tree().get_nodes_in_group("allies"):
		if is_instance_valid(ally) and ally.has_method("take_damage"):
			if global_position.distance_to(ally.global_position) < EXPLODE_RANGE:
				ally.take_damage(EXPLODE_DMG / 2)
	SoundManager.play("explode")
	died.emit(self)
	queue_free()

func take_damage(amount: int) -> void:
	hp -= amount
	modulate = Color(1.8, 0.25, 0.25)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.10)
	queue_redraw()
	if hp <= 0:
		_explode()

func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	if _primed:
		var wpulse := 0.45 + sin(_fuse_t * 28.0) * 0.45
		draw_circle(Vector2.ZERO, r * (1.9 + _fuse_t * 0.8), Color(1.0, 0.3, 0.0, wpulse * 0.55))

	draw_circle(Vector2(2, 3), r * 1.0, Color(0, 0, 0, 0.28))
	draw_circle(Vector2.ZERO, r * 0.92, c.darkened(0.30))
	draw_circle(Vector2.ZERO, r * 0.80, c)

	var core_speed := 14.0 if _primed else 3.5
	var core_pulse := 0.60 + sin(_fuse_t * core_speed) * 0.38
	draw_circle(Vector2.ZERO, r * 0.40, Color(1.0, 0.80, 0.10, core_pulse))
	draw_circle(Vector2.ZERO, r * 0.20, Color(1.0, 1.0,  0.55, core_pulse))

	for i in 4:
		var a  := TAU * float(i) / 4.0 + PI / 4.0
		var ld := Vector2(cos(a), sin(a))
		draw_line(ld * r * 0.55, ld * r * 1.05, c.darkened(0.20), 3.5)

	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.52 + p * s * r * 0.30
		draw_circle(ep, 2.8, Color(1.0, 0.15, 0.0))
		draw_circle(ep, 1.2, Color(0.0,  0.0,  0.0))

	draw_arc(Vector2.ZERO, r, 0, TAU, 24, c.lightened(0.32), 1.5)

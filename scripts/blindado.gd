extends "res://scripts/larva.gd"

const CHARGE_SPEED    := 380.0
const CHARGE_DURATION := 0.38
const CHARGE_COOLDOWN := 6.0
const STUCK_THRESHOLD := 2.8

var _charge_cd: float   = 4.0
var _charge_t:  float   = 0.0
var _charging:  bool    = false
var _last_pos:  Vector2 = Vector2.ZERO
var _stuck_t:   float   = 0.0

func _ready() -> void:
	max_hp       = 400
	melee_damage = 40
	body_color   = Color(0.3, 0.32, 0.38)
	body_radius  = 20.0
	super._ready()

func _physics_process(delta: float) -> void:
	_charge_cd -= delta
	if _charging:
		_charge_t -= delta
		velocity   = _draw_dir * CHARGE_SPEED
		move_and_slide()
		if velocity.length_squared() > 1.0:
			_draw_dir = velocity.normalized()
		_wall_dmg_cd -= delta
		if _wall_dmg_cd <= 0.0:
			for ci in get_slide_collision_count():
				var col  := get_slide_collision(ci)
				var body := col.get_collider()
				if is_instance_valid(body) and (body.collision_layer & 8) and body.has_method("take_damage"):
					body.take_damage(80)
					_wall_dmg_cd = DAMAGE_INTERVAL
					break
		_dmg_cd -= delta
		if _dmg_cd <= 0.0:
			_try_melee_proximity()
		if _charge_t <= 0.0:
			_charging  = false
			_charge_cd = CHARGE_COOLDOWN
		queue_redraw()
		return
	var moved := global_position.distance_to(_last_pos)
	_last_pos  = global_position
	if moved < 5.0 * delta:
		_stuck_t += delta
	else:
		_stuck_t = 0.0
	if _charge_cd <= 0.0 and _stuck_t >= STUCK_THRESHOLD and is_instance_valid(player):
		_stuck_t  = 0.0
		_charging = true
		_charge_t = CHARGE_DURATION
		_draw_dir = (player.global_position - global_position).normalized()
		modulate  = Color(1.8, 0.4, 0.4)
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color.WHITE, 0.3)
		queue_redraw()
		return
	super._physics_process(delta)

func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	draw_circle(Vector2(3, 5), r * 1.05, Color(0, 0, 0, 0.32))

	draw_circle(Vector2.ZERO, r * 0.90, c.darkened(0.25))
	draw_circle(d * r * 0.22, r * 0.78, c)

	# Armor plate arcs
	var ac := c.lightened(0.18)
	draw_arc(Vector2.ZERO,    r * 0.82, PI * 0.55, PI * 1.45, 16, ac, 3.5)
	draw_arc(d * r * 0.18,   r * 0.68, -PI * 0.38, PI * 0.38, 12, ac, 4.0)
	draw_arc(-d * r * 0.12,  r * 0.70, PI * 0.65,  PI * 1.35, 12, ac.darkened(0.1), 3.0)

	# Carapace spikes on back
	for i in 3:
		var sp := -d * r * 0.60 + p * r * ((i - 1.0) * 0.42)
		draw_line(sp, sp - d * r * 0.30, c.lightened(0.28), 3.5)

	# Stubby legs (2 pairs)
	for i in 2:
		var base := d * r * ((i - 0.5) * 0.48)
		for s: float in [-1.0, 1.0]:
			var knee := base + p * s * r * 0.72
			var foot := knee + p * s * r * 0.28 + d * r * 0.08
			draw_line(base, knee, c.darkened(0.05), 4.5)
			draw_line(knee, foot, c.darkened(0.20), 3.5)

	# Two massive front claws
	for s: float in [-1.0, 1.0]:
		var root := d * r * 0.72 + p * s * r * 0.30
		var mid  := d * r * 1.18 + p * s * r * 0.58
		var tipA := d * r * 1.50 + p * s * r * 0.32
		var tipB := d * r * 1.35 + p * s * r * 0.78
		draw_line(root, mid,  c.lightened(0.12), 5.5)
		draw_line(mid,  tipA, c.lightened(0.22), 3.8)
		draw_line(mid,  tipB, c.lightened(0.22), 3.8)

	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.68 + p * s * r * 0.20
		draw_circle(ep, 3.8, Color(0.55, 0.78, 1.0, 0.85))
		draw_circle(ep, 1.6, Color(0.0,  0.0,  0.12))

	draw_arc(Vector2.ZERO, r * 0.90, 0, TAU, 32, c.lightened(0.22), 1.8)

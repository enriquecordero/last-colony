extends "res://scripts/larva.gd"

# Siege alien: slow, heavily armoured, actively seeks and pounds structures.
# Ignores the player unless no structures are in range.

var walls_node: Node2D

const DETECT_R   := 220.0   # radius to scan for structures
const SIEGE_R    := 55.0    # stop-and-attack range
const SIEGE_DMG  := 115     # damage per pound
const SIEGE_RATE := 1.7     # seconds between hits
const SIEGE_SPEED := 22.0

var _siege_target: Node2D = null
var _siege_cd:     float  = 0.0
var _scan_cd:      float  = 0.0
var _hit_flash:    float  = 0.0
var _aura_t:       float  = 0.0


func _ready() -> void:
	max_hp       = 1400
	melee_damage = 18
	body_color   = Color(0.12, 0.20, 0.08)
	body_radius  = 30.0
	speed        = SIEGE_SPEED
	super._ready()


func _physics_process(delta: float) -> void:
	_siege_cd -= delta
	_scan_cd  -= delta
	_aura_t   += delta
	_hit_flash = maxf(_hit_flash - delta * 3.5, 0.0)

	if _scan_cd <= 0.0:
		_scan_cd      = 0.65
		_siege_target = _find_siege_target()

	if is_instance_valid(_siege_target):
		var to_t := _siege_target.global_position - global_position
		if to_t.length() > 1.0:
			_draw_dir = to_t.normalized()
		if to_t.length() > SIEGE_R:
			velocity = _draw_dir * SIEGE_SPEED
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			if _siege_cd <= 0.0:
				_pound(_siege_target)
		queue_redraw()
		return

	super._physics_process(delta)


func _find_siege_target() -> Node2D:
	var best:   Node2D = null
	var best_d: float  = DETECT_R

	if is_instance_valid(walls_node):
		for s in walls_node.get_children():
			if not is_instance_valid(s) or not s.has_method("take_damage"):
				continue
			var d := global_position.distance_to(s.global_position)
			if d < best_d:
				best_d = d
				best   = s

	if is_instance_valid(fortress) and fortress.has_method("get_damageable_walls"):
		for fw in fortress.get_damageable_walls():
			if not is_instance_valid(fw):
				continue
			var hp_v: Variant = fw.get("hp")
			if hp_v != null and int(hp_v) <= 0:
				continue
			var d := global_position.distance_to(fw.global_position)
			if d < best_d:
				best_d = d
				best   = fw

	return best


func _pound(target: Node) -> void:
	if not is_instance_valid(target):
		_siege_target = null
		return
	target.take_damage(SIEGE_DMG)
	if target.has_method("queue_redraw"):
		target.queue_redraw()
	_siege_cd  = SIEGE_RATE
	_hit_flash = 1.0
	var hp_v: Variant = target.get("hp")
	if hp_v != null and int(hp_v) <= 0:
		_siege_target = null
	queue_redraw()


func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	# Sombra masiva
	draw_circle(d * 4 + Vector2(0, 8), r * 1.18, Color(0, 0, 0, 0.42))

	# Cuerpo principal
	draw_circle(Vector2.ZERO, r * 0.94, c.darkened(0.30))
	draw_circle(Vector2.ZERO, r * 0.84, c)

	# Placas de blindaje
	var ac := c.lightened(0.20)
	draw_arc(Vector2.ZERO,     r * 0.88, PI * 0.48, PI * 1.52, 20, ac, 5.5)
	draw_arc(d * r * 0.12,    r * 0.72, -PI * 0.40, PI * 0.40, 14, ac.lightened(0.10), 6.5)
	draw_arc(-d * r * 0.18,   r * 0.73, PI * 0.58,  PI * 1.42, 14, ac.darkened(0.10), 5.0)

	# Cabeza de ariete (cambia a naranja en impacto)
	var ram_base := c.lightened(0.38)
	var ram_col  := ram_base.lerp(Color(1.0, 0.45, 0.05), _hit_flash)
	draw_arc(d * r * 0.62, r * 0.44, -PI * 0.38, PI * 0.38, 14, ram_col, 8.0)
	draw_arc(d * r * 0.82, r * 0.28, -PI * 0.30, PI * 0.30, 10, ram_col.lightened(0.15), 6.0)

	# Refuerzos laterales
	for s: float in [-1.0, 1.0]:
		var base := -d * r * 0.42 + p * s * r * 0.68
		draw_line(base, base - d * r * 0.30 + p * s * r * 0.25, c.lightened(0.32), 5.0)
		draw_line(base, base + p * s * r * 0.32, c.lightened(0.22), 3.5)

	# Patas pesadas
	for i in 3:
		var base := d * r * ((i - 1.0) * 0.42)
		for s: float in [-1.0, 1.0]:
			var knee := base + p * s * r * 0.82
			var foot := knee + p * s * r * 0.24 + d * r * 0.05
			draw_line(base, knee, c.darkened(0.08), 7.0)
			draw_line(knee, foot, c.darkened(0.24), 5.0)

	# Ojos pequeños, hundidos
	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.60 + p * s * r * 0.26
		draw_circle(ep, 4.2, Color(0.50, 0.70, 0.10, 0.90))
		draw_circle(ep, 1.7, Color(0.0,  0.0,  0.0))

	draw_arc(Vector2.ZERO, r * 0.90, 0, TAU, 36, c.lightened(0.22), 2.0)

	# Aura naranja cuando tiene objetivo estructural
	if is_instance_valid(_siege_target):
		var ap := 0.22 + 0.18 * abs(sin(_aura_t * 4.5))
		draw_arc(Vector2.ZERO, r + 7.0, 0, TAU, 28, Color(1.0, 0.52, 0.0, ap), 3.0)

extends Node2D

# Green alien blood splatter. Spawned on enemy hit; caller sets:
#   hit_direction — normalized vector bullet was travelling (droplets spray backward/sideways)

var hit_direction: Vector2 = Vector2.RIGHT

const DROP_COUNT := 12
const DURATION   := 0.28

var _t:    float = 0.0
var _drops: Array = []   # [{pos, vel, r, shade}]


func _ready() -> void:
	_init_drops()


func _init_drops() -> void:
	var back := -hit_direction
	for i in DROP_COUNT:
		var angle_offset := randf_range(-PI * 0.72, PI * 0.72)
		var spread_dir   := back.rotated(angle_offset)
		var speed        := randf_range(28.0, 110.0)
		_drops.append({
			"pos":   Vector2.ZERO,
			"vel":   spread_dir * speed,
			"r":     randf_range(1.4, 4.2),
			"shade": randf_range(0.55, 1.0),   # brightness for green channel
			"alpha": 1.0,
		})


func _process(delta: float) -> void:
	_t += delta / DURATION
	if _t >= 1.0:
		queue_free()
		return

	var drag := 1.0 - delta * 7.0
	for d in _drops:
		d["vel"] *= drag
		d["pos"] += d["vel"] * delta
		d["alpha"] = lerpf(1.0, 0.0, _t * _t)

	queue_redraw()


func _draw() -> void:
	var base_alpha: float = lerpf(1.0, 0.0, _t * _t)

	# Central burst
	var burst_r := lerpf(5.0, 1.0, _t)
	draw_circle(Vector2.ZERO, burst_r,
		Color(0.05, 0.85, 0.10, base_alpha * 0.9))

	# Droplets
	for d in _drops:
		var g: float = d["shade"]
		var a: float = d["alpha"]
		var r: float = d["r"] * lerpf(1.0, 0.3, _t)
		draw_circle(d["pos"], r, Color(0.02, g, 0.05, a))

	# Short streak lines from center outward along each droplet
	for d in _drops:
		if d["vel"].length_squared() < 4.0:
			continue
		var tip := d["pos"]
		var tail := tip - d["vel"].normalized() * minf(d["vel"].length() * 0.06, 8.0)
		var a: float = d["alpha"] * 0.6
		draw_line(tail, tip, Color(0.04, d["shade"] * 0.8, 0.06, a), 1.2)

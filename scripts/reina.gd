extends "res://scripts/engendro.gd"

# Stage 2 boss — larger, acid-spitting queen variant of the Engendro.

const AcidPool    = preload("res://scripts/acid_pool.gd")
const LarvaScene2 = preload("res://scenes/larva.tscn")

const ACID_CD_TIME := 7.0
var _acid_cd: float = ACID_CD_TIME * 0.5
var _acid_node_parent: Node = null   # set by main.gd — top-level node to add pools


func _ready() -> void:
	max_hp      = 1800
	hp          = max_hp
	body_color  = Color(0.55, 0.02, 0.75)
	super._ready()


func _physics_process(delta: float) -> void:
	_acid_cd -= delta
	if _acid_cd <= 0.0:
		_acid_cd = ACID_CD_TIME * (0.6 if _phase2 else 1.0)
		_do_acid_spit()
	super._physics_process(delta)


func _do_acid_spit() -> void:
	if not is_instance_valid(player):
		return
	var parent := _acid_node_parent if is_instance_valid(_acid_node_parent) else get_parent()
	var count  := 3 if _phase2 else 2
	for i in count:
		var pool          := AcidPool.new()
		var spread        := Vector2(randf_range(-55, 55), randf_range(-55, 55))
		var dir           := (player.global_position - global_position).normalized()
		pool.global_position = global_position + dir * 60.0 + spread
		pool.player          = player
		parent.add_child(pool)


func _draw() -> void:
	if _dying:
		var pct := minf(_die_t / DIE_DUR, 1.0)
		var er  := 22.0 + pct * 130.0
		draw_circle(Vector2.ZERO, er,        Color(0.65, 0.0, 0.9, (1.0 - pct) * 0.85))
		draw_circle(Vector2.ZERO, er * 0.55, Color(1.0, 0.55, 1.0,  (1.0 - pct)))
		draw_arc(Vector2.ZERO, er * 1.15, 0, TAU, 48, Color(0.8, 0.2, 1.0, (1.0 - pct) * 0.5), 5.0)
		return

	var pulse_spd := 5.5 if _phase2 else 2.4
	var pulse     := 0.82 + sin(_t * pulse_spd) * 0.18
	var d         := _draw_dir
	var p         := Vector2(-d.y, d.x)
	var c         := body_color
	var lc        := c.darkened(0.32)
	var r         := 26.0  # slightly larger than engendro

	# Shadow
	draw_circle(Vector2(5, 10), r + 4, Color(0, 0, 0, 0.42))

	# Charge trail
	if _charging:
		draw_line(Vector2.ZERO, -_charge_dir * 30.0, Color(0.7, 0.15, 1.0, 0.5), 16.0)

	# Limbs — 6 in phase2, 4 otherwise
	var limb_count := 6 if _phase2 else 4
	for i in limb_count:
		var wave  := sin(_t * 3.2 + i * 1.1) * 0.12
		var base_a := atan2(d.y, d.x) + TAU * i / float(limb_count) + wave
		var ld    := Vector2(cos(base_a), sin(base_a))
		var lp2   := Vector2(-ld.y, ld.x)
		var root  := ld * 15.0
		var joint := ld * 30.0 + lp2 * (7.0 * sin(_t * 2.2 + i))
		var tip   := joint + ld * 18.0
		draw_line(root,  joint, lc,                 6.5)
		draw_line(joint, tip,   lc.lightened(0.08), 4.5)
		draw_line(tip, tip + ld * 9.0 + lp2 *  5.0, lc.lightened(0.22), 3.0)
		draw_line(tip, tip + ld * 9.0 - lp2 *  5.0, lc.lightened(0.22), 3.0)

	# Egg-sac abdomen
	draw_circle(-d * 12.0, r * 0.68, c.darkened(0.35))
	draw_circle(-d * 12.0, r * 0.55, c.darkened(0.15))
	# Acid sacs on abdomen
	for i in 3:
		var a  := TAU * i / 3.0 + PI * 0.3
		var bp := -d * r * 0.52 + Vector2(cos(a), sin(a)) * r * 0.28
		draw_circle(bp, r * 0.15, Color(0.55, 1.0, 0.12, 0.80))

	# Main body
	draw_circle(Vector2.ZERO, r,        c.darkened(0.38))
	draw_circle(Vector2.ZERO, r * 0.82, c)
	# Head
	draw_circle(d * 14.0, r * 0.55, c.lightened(0.10))

	# Mandibles
	for s2: float in [-1.0, 1.0]:
		draw_line(d * 17.0 + p * s2 * 5.0,
		          d * 28.0 + p * s2 * 12.0,
		          c.lightened(0.28), 4.5)
		draw_line(d * 28.0 + p * s2 * 12.0,
		          d * 33.0 + p * s2 *  6.0,
		          c.lightened(0.20), 3.0)

	# Crown of spines (phase2)
	if _phase2:
		draw_arc(Vector2.ZERO, r + 8.0, 0, TAU, 36,
			Color(0.80, 0.15, 1.0, 0.40 * pulse), 4.5)

	# Armor ring
	draw_arc(Vector2.ZERO, r,        0, TAU, 28, c.lightened(0.28) * pulse, 2.5)

	# Eyes — 3 main + 2 on head
	for i in 3:
		var a  := -PI * 0.5 + TAU * i / 3.0
		var ep := Vector2(cos(a), sin(a)) * r * 0.52
		draw_circle(ep,        5.2, Color(0.75, 0.0, 0.95, 0.75 + 0.25 * pulse))
		draw_circle(ep * 0.4,  2.2, Color(1.0, 0.82, 0.0))
	for s2: float in [-1.0, 1.0]:
		var he := d * 16.0 + p * s2 * 5.5
		draw_circle(he, 3.8, Color(0.90, 0.10, 0.95, 0.85 + 0.15 * pulse))
		draw_circle(he, 1.6, Color(1.0, 0.90, 0.0))

	# Health bar
	var bw := 52.0
	draw_rect(Rect2(-bw * 0.5, -38, bw, 5), Color(0.06, 0.0, 0.08, 0.92))
	draw_rect(Rect2(-bw * 0.5, -38, bw * float(hp) / float(max_hp), 5),
		Color(0.80, 0.10, 0.95) if not _phase2 else Color(1.0, 0.20, 0.80))
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-34, -45), "LA REINA",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.88, 0.35, 1.0, 0.92))

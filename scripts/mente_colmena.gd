extends CharacterBody2D

signal died(node)
signal summoned_larva(enemy)
signal rugido_emitted()
signal phase2_entered()
signal phase3_entered()
signal corrosive_pulse_emitted(pos: Vector2, radius: float)

const DestructorScene = preload("res://scenes/destructor.tscn")
const CorruptorScene  = preload("res://scenes/corruptor.tscn")
const LarvaScene      = preload("res://scenes/larva.tscn")

const MAX_HP        := 9000
const SPEED_P1      := 42.0
const SPEED_P2      := 62.0
const SPEED_P3      := 95.0
const MELEE_DMG     := 75
const MELEE_RANGE   := 45.0
const MELEE_CD_TIME := 1.4

const EMBESTIDA_CD  := 10.0
const LLAMADO_CD    := 14.0
const RUGIDO_CD     := 22.0
const PULSO_CD_P2   := 12.0
const PULSO_CD_P3   := 5.0
const PULSO_RADIUS  := 300.0
const CHARGE_SPEED  := 380.0
const CHARGE_DIST   := 420.0

var hp:               int     = MAX_HP
var max_hp:           int     = MAX_HP
var body_color:       Color   = Color(0.45, 0.05, 0.65)
var player:           Node2D
var base_pos:         Vector2 = Vector2.ZERO
var bullet_container: Node2D
var fortress:         Node2D
var walls_node:       Node2D

var _t:          float = 0.0
var _melee_cd:   float = 0.0
var _embestida:  float = EMBESTIDA_CD * 0.6
var _llamado:    float = LLAMADO_CD
var _rugido:     float = RUGIDO_CD
var _pulso_cd:   float = PULSO_CD_P2
var _charging:   bool  = false
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_rem: float   = 0.0
var _phase:      int     = 1
var _draw_dir:   Vector2 = Vector2.RIGHT
var _dying:      bool    = false
var _die_t:      float   = 0.0
const DIE_DUR            := 1.8

const BODY_R := 38.0


func _ready() -> void:
	collision_layer = 2
	collision_mask  = 1
	var shape    = CircleShape2D.new()
	shape.radius = BODY_R * 0.85
	var col      = CollisionShape2D.new()
	col.shape    = shape
	add_child(col)


func _physics_process(delta: float) -> void:
	if _dying:
		_die_t += delta
		queue_redraw()
		if _die_t >= DIE_DUR:
			died.emit(self)
			queue_free()
		return

	_t        += delta
	_melee_cd -= delta
	_embestida -= delta
	_llamado  -= delta
	_rugido   -= delta
	_pulso_cd -= delta

	if _charging:
		_tick_charge(delta)
	else:
		_tick_walk(delta)

	_tick_attacks()
	queue_redraw()


func _tick_walk(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var spd := SPEED_P3 if _phase == 3 else (SPEED_P2 if _phase == 2 else SPEED_P1)
	velocity = (player.global_position - global_position).normalized() * spd
	move_and_slide()
	if velocity.length_squared() > 1.0:
		_draw_dir = velocity.normalized()
	if _melee_cd <= 0.0 and global_position.distance_to(player.global_position) < MELEE_RANGE:
		player.take_damage(MELEE_DMG)
		_melee_cd = MELEE_CD_TIME


func _tick_charge(delta: float) -> void:
	velocity = _charge_dir * CHARGE_SPEED
	move_and_slide()
	_charge_rem -= CHARGE_SPEED * delta

	if is_instance_valid(walls_node):
		for w in walls_node.get_children():
			if is_instance_valid(w) and w.has_method("take_damage"):
				if global_position.distance_to(w.global_position) < 40.0:
					w.take_damage(9999)

	if _melee_cd <= 0.0 and is_instance_valid(player):
		if global_position.distance_to(player.global_position) < 42.0:
			player.take_damage(120)
			_melee_cd = MELEE_CD_TIME
			_charging = false
			return

	if _charge_rem <= 0.0:
		_charging = false


func _tick_attacks() -> void:
	if _embestida <= 0.0:
		_start_embestida()
		_embestida = 6.0 if _phase >= 2 else EMBESTIDA_CD

	if _llamado <= 0.0:
		_do_llamado()
		var cd := 5.0 if _phase == 3 else (9.0 if _phase == 2 else LLAMADO_CD)
		_llamado = cd

	if _rugido <= 0.0:
		rugido_emitted.emit()
		_rugido = 18.0 if _phase >= 2 else RUGIDO_CD

	if _phase >= 2 and _pulso_cd <= 0.0:
		_do_pulso()
		_pulso_cd = PULSO_CD_P3 if _phase == 3 else PULSO_CD_P2


func _start_embestida() -> void:
	if not is_instance_valid(player):
		return
	_charging   = true
	_charge_dir = (player.global_position - global_position).normalized()
	_charge_rem = CHARGE_DIST


func _do_llamado() -> void:
	if _phase == 3:
		# Phase 3: mix of corruptors and larvas in continuous swarm
		for i in 8:
			var use_corruptor := (i % 3 == 0)
			var e = CorruptorScene.instantiate() if use_corruptor else LarvaScene.instantiate()
			_setup_enemy(e, i, 8)
			summoned_larva.emit(e)
	elif _phase == 2:
		# Phase 2: destructors + corruptors
		for i in 4:
			var e = DestructorScene.instantiate()
			_setup_enemy(e, i, 4)
			summoned_larva.emit(e)
		for i in 3:
			var e = CorruptorScene.instantiate()
			_setup_enemy(e, i + 4, 8)
			summoned_larva.emit(e)
	else:
		# Phase 1: destructors
		for i in 3:
			var e = DestructorScene.instantiate()
			_setup_enemy(e, i, 3)
			summoned_larva.emit(e)


func _setup_enemy(e: Node, idx: int, total: int) -> void:
	var a := TAU * float(idx) / float(total)
	e.position         = global_position + Vector2(cos(a), sin(a)) * 80.0
	e.player           = player
	e.base_pos         = base_pos
	e.bullet_container = bullet_container
	if "fortress" in e:    e.fortress    = fortress
	if "walls_node" in e:  e.walls_node  = walls_node


func _do_pulso() -> void:
	# Damage all walls in radius
	if is_instance_valid(walls_node):
		for w in walls_node.get_children():
			if is_instance_valid(w) and w.has_method("take_damage"):
				if global_position.distance_to(w.global_position) < PULSO_RADIUS:
					w.take_damage(80 if _phase == 3 else 50)
	if is_instance_valid(fortress) and fortress.has_method("get_damageable_walls"):
		for fw in fortress.get_damageable_walls():
			if is_instance_valid(fw) and fw.has_method("take_damage"):
				if global_position.distance_to(fw.global_position) < PULSO_RADIUS:
					fw.take_damage(80 if _phase == 3 else 50)
	corrosive_pulse_emitted.emit(global_position, PULSO_RADIUS)
	rugido_emitted.emit()


func take_damage(amount: int) -> void:
	if _dying:
		return
	hp = max(0, hp - amount)
	modulate = Color(1.4, 0.2, 1.4)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	queue_redraw()

	if _phase == 1 and hp <= max_hp * 2 / 3:
		_enter_phase2()
	elif _phase == 2 and hp <= max_hp / 3:
		_enter_phase3()
	if hp <= 0:
		_start_dying()


func _start_dying() -> void:
	_dying   = true
	_die_t   = 0.0
	velocity = Vector2.ZERO
	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = true
	SoundManager.play("explode")


func _enter_phase2() -> void:
	_phase     = 2
	body_color = Color(0.60, 0.02, 0.80)
	_embestida = 2.0
	_llamado   = 2.0
	_pulso_cd  = 2.0
	phase2_entered.emit()


func _enter_phase3() -> void:
	_phase     = 3
	body_color = Color(0.90, 0.05, 0.50)
	_embestida = 1.5
	_llamado   = 1.5
	_pulso_cd  = 1.0
	phase3_entered.emit()
	phase2_entered.emit()  # also fire phase2 signal so main.gd announces it


func _draw() -> void:
	if _dying:
		var pct := minf(_die_t / DIE_DUR, 1.0)
		var er  := BODY_R + pct * 160.0
		draw_circle(Vector2.ZERO, er,        Color(0.80, 0.10, 1.0, (1.0 - pct) * 0.80))
		draw_circle(Vector2.ZERO, er * 0.50, Color(1.0,  0.55, 1.0, (1.0 - pct)))
		draw_arc(Vector2.ZERO,    er * 1.20, 0, TAU, 48, Color(0.9, 0.2, 1.0, (1.0 - pct) * 0.5), 6.0)
		return

	var pulse_spd := 6.5 if _phase == 3 else (4.5 if _phase == 2 else 2.2)
	var pulse     := 0.80 + sin(_t * pulse_spd) * 0.20
	var d         := _draw_dir
	var p         := Vector2(-d.y, d.x)
	var r         := BODY_R
	var c         := body_color
	var lc        := c.darkened(0.35)

	# Shadow
	draw_circle(Vector2(6, 12), r * 1.15, Color(0, 0, 0, 0.45))

	# Charge trail
	if _charging:
		draw_line(Vector2.ZERO, -_charge_dir * 36.0, Color(0.8, 0.2, 1.0, 0.5), 18.0)

	# Tentacles / tendrils (8 in phase 3, 6 in phase 2, 4 in phase 1)
	var tendril_count := 8 if _phase == 3 else (6 if _phase == 2 else 4)
	for i in tendril_count:
		var wave    := sin(_t * 3.2 + i * 0.9) * 0.14
		var base_a  := atan2(d.y, d.x) + TAU * i / float(tendril_count) + wave
		var ld      := Vector2(cos(base_a), sin(base_a))
		var lp2     := Vector2(-ld.y, ld.x)
		var root    := ld * 18.0
		var joint   := ld * 34.0 + lp2 * (8.0 * sin(_t * 2.0 + i))
		var tip     := joint + ld * 20.0
		draw_line(root,  joint, lc,                   7.0)
		draw_line(joint, tip,   lc.lightened(0.10),   5.0)
		draw_line(tip, tip + ld * 10.0 + lp2 * 6.0, lc.lightened(0.22), 3.0)
		draw_line(tip, tip + ld * 10.0 - lp2 * 6.0, lc.lightened(0.22), 3.0)

	# Abdomen
	draw_circle(-d * 14.0, r * 0.55, c.darkened(0.35))
	# Main body
	draw_circle(Vector2.ZERO, r,        c.darkened(0.38))
	draw_circle(Vector2.ZERO, r * 0.82, c)
	# Head lobe
	draw_circle(d * 16.0, r * 0.52, c.lightened(0.10))

	# Corrosive vein lines (phase 2+)
	if _phase >= 2:
		var vein_c := Color(0.60, 1.0, 0.15, 0.55 * pulse)
		for i in 6:
			var a  := TAU * i / 6.0 + _t * 0.4
			var v0 := Vector2(cos(a), sin(a)) * r * 0.35
			var v1 := Vector2(cos(a + 0.4), sin(a + 0.4)) * r * 0.82
			draw_line(v0, v1, vein_c, 2.0)

	# Phase 3 outer corona
	if _phase == 3:
		draw_arc(Vector2.ZERO, r + 10.0, 0, TAU, 40,
			Color(1.0, 0.20, 0.55, 0.45 * pulse), 5.0)

	# Armor ring
	draw_arc(Vector2.ZERO, r,        0, TAU, 32, c.lightened(0.28) * pulse, 2.5)
	draw_arc(Vector2.ZERO, r * 1.08, 0, TAU, 32, Color(c.r, c.g, c.b, 0.28 * pulse), 2.0)

	# Eye cluster — 5 eyes
	for i in 5:
		var a  := -PI * 0.5 + TAU * i / 5.0
		var ep := Vector2(cos(a), sin(a)) * r * 0.50
		draw_circle(ep,        6.0, Color(0.85, 0.05, 0.95, 0.75 + 0.25 * pulse))
		draw_circle(ep * 0.4,  2.8, Color(1.00, 0.80, 0.0))
	# Two on head
	for s: float in [-1.0, 1.0]:
		var he := d * 18.0 + p * s * 6.0
		draw_circle(he, 4.5, Color(1.0, 0.15, 0.90, 0.85 + 0.15 * pulse))
		draw_circle(he, 2.0, Color(1.0, 0.90, 0.0))

	# Mandibles
	for s: float in [-1.0, 1.0]:
		draw_line(d * 20.0 + p * s * 5.0,
		          d * 32.0 + p * s * 14.0,
		          c.lightened(0.28), 5.0)
		draw_line(d * 32.0 + p * s * 14.0,
		          d * 38.0 + p * s * 7.0,
		          c.lightened(0.20), 3.5)

	# Health bar
	var bw := 68.0
	draw_rect(Rect2(-bw * 0.5, -50, bw, 6), Color(0.08, 0.0, 0.08, 0.92))
	var hp_frac := float(hp) / float(max_hp)
	var bar_c   := Color(0.55, 0.05, 0.90) if _phase == 1 \
		else (Color(0.80, 0.08, 0.60) if _phase == 2 else Color(1.0, 0.15, 0.45))
	draw_rect(Rect2(-bw * 0.5, -50, bw * hp_frac, 6), bar_c)

	# Phase threshold markers
	draw_line(Vector2(-bw * 0.5 + bw * 0.333, -52),
	          Vector2(-bw * 0.5 + bw * 0.333, -44), Color(1, 1, 1, 0.5), 1.5)
	draw_line(Vector2(-bw * 0.5 + bw * 0.667, -52),
	          Vector2(-bw * 0.5 + bw * 0.667, -44), Color(1, 1, 1, 0.5), 1.5)

	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-46, -57), "MENTE COLMENA",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.35, 1.0, 0.92))
	draw_string(f, Vector2(-46, -57 + 46), "FASE %d" % _phase,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, bar_c * Color(1.3, 1.3, 1.3))

extends CharacterBody2D

signal died(node)
signal summoned_larva(enemy)
signal rugido_emitted()
signal phase2_entered()

const LarvaScene = preload("res://scenes/larva.tscn")

const MAX_HP        := 800
const SPEED         := 65.0
const MELEE_DMG     := 60
const MELEE_RANGE   := 38.0
const MELEE_CD_TIME := 1.2

const EMBESTIDA_CD   := 8.0
const LLAMADO_CD     := 12.0
const RUGIDO_CD      := 20.0
const CHARGE_SPEED   := 520.0
const CHARGE_DIST    := 450.0

var hp:               int     = MAX_HP
var max_hp:           int     = MAX_HP
var body_color:       Color   = Color(0.60, 0.05, 0.05)
var player:           Node2D
var base_pos:         Vector2 = Vector2.ZERO
var bullet_container: Node2D
var fortress:         Node2D
var walls_node:       Node2D

var _t:          float = 0.0
var _melee_cd:   float = 0.0
var _embestida:  float = EMBESTIDA_CD * 0.5
var _llamado:    float = LLAMADO_CD
var _rugido:     float = RUGIDO_CD
var _charging:   bool  = false
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_rem: float  = 0.0
var _phase2:     bool  = false
var _sprite:     Sprite2D = null


func _ready() -> void:
	collision_layer = 2
	collision_mask  = 1
	var shape        = CircleShape2D.new()
	shape.radius     = 22.0
	var col          = CollisionShape2D.new()
	col.shape        = shape
	add_child(col)


func _physics_process(delta: float) -> void:
	_t += delta
	if _charging:
		_tick_charge(delta)
	else:
		_tick_walk(delta)
	_tick_attacks(delta)
	_melee_cd -= delta
	queue_redraw()


func _tick_walk(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var spd := 110.0 if _phase2 else SPEED
	velocity = (player.global_position - global_position).normalized() * spd
	move_and_slide()
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
				if global_position.distance_to(w.global_position) < 30.0:
					w.take_damage(9999)

	if _melee_cd <= 0.0 and is_instance_valid(player):
		if global_position.distance_to(player.global_position) < 32.0:
			player.take_damage(100)
			_melee_cd = MELEE_CD_TIME
			_charging = false
			return

	if _charge_rem <= 0.0:
		_charging = false


func _tick_attacks(delta: float) -> void:
	_embestida -= delta
	_llamado   -= delta
	_rugido    -= delta

	if _embestida <= 0.0:
		_start_embestida()
		_embestida = 4.5 if _phase2 else EMBESTIDA_CD

	if _llamado <= 0.0:
		_do_llamado()
		_llamado = 6.0 if _phase2 else LLAMADO_CD

	if _rugido <= 0.0:
		_do_rugido()
		_rugido = 13.0 if _phase2 else RUGIDO_CD


func _start_embestida() -> void:
	if not is_instance_valid(player):
		return
	_charging    = true
	_charge_dir  = (player.global_position - global_position).normalized()
	_charge_rem  = CHARGE_DIST


func _do_llamado() -> void:
	var count := 10 if _phase2 else 6
	for i in count:
		var e = LarvaScene.instantiate()
		var a := TAU * i / float(count)
		e.position         = global_position + Vector2(cos(a), sin(a)) * 70.0
		e.player           = player
		e.base_pos         = base_pos
		e.bullet_container = bullet_container
		if "fortress" in e:
			e.fortress = fortress
		summoned_larva.emit(e)


func _do_rugido() -> void:
	rugido_emitted.emit()


func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	modulate = Color(1.5, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	queue_redraw()
	if not _phase2 and hp <= max_hp / 2:
		_enter_phase2()
	if hp <= 0:
		died.emit(self)
		queue_free()

func _enter_phase2() -> void:
	_phase2      = true
	# Velocidad y cadencias más agresivas
	const P2_SPEED      := 110.0
	const P2_EMBESTIDA  := 4.5
	const P2_LLAMADO    := 6.0
	const P2_RUGIDO     := 14.0
	_embestida = P2_EMBESTIDA * 0.3   # primera embestida casi inmediata
	_llamado   = P2_LLAMADO   * 0.2
	_rugido    = P2_RUGIDO    * 0.5
	body_color = Color(0.95, 0.05, 0.02)
	phase2_entered.emit()


func _draw() -> void:
	var pulse_spd := 5.5 if _phase2 else 2.4
	var pulse := 0.82 + sin(_t * pulse_spd) * 0.18

	draw_circle(Vector2(5, 9), 26, Color(0, 0, 0, 0.4))

	if _charging:
		var back := -_charge_dir * 28.0
		draw_line(Vector2.ZERO, back, Color(1.0, 0.45, 0.0, 0.5), 14.0)

	draw_circle(Vector2.ZERO, 22, body_color.darkened(0.35))
	draw_circle(Vector2.ZERO, 18, body_color)
	draw_arc(Vector2.ZERO, 18, 0, TAU, 28, body_color.lightened(0.25) * pulse, 2.5)
	draw_arc(Vector2.ZERO, 23, 0, TAU, 28, Color(0.9, 0.15, 0.1, 0.3 * pulse), 1.5)

	if _phase2:
		draw_arc(Vector2.ZERO, 28, 0, TAU, 32, Color(1.0, 0.15, 0.0, 0.35 * pulse), 4.0)

	for i in 3:
		var a  := -PI * 0.5 + TAU * i / 3.0
		var ep := Vector2(cos(a), sin(a)) * 9.0
		draw_circle(ep, 5.0, Color(0.9, 0.08, 0.0, 0.7 + 0.3 * pulse))
		draw_circle(ep * 0.35, 2.2, Color(1.0, 0.85, 0.0))

	var bw := 46.0
	draw_rect(Rect2(-bw * 0.5, -33, bw, 5), Color(0.08, 0.0, 0.0, 0.9))
	draw_rect(Rect2(-bw * 0.5, -33, bw * float(hp) / float(max_hp), 5), Color(0.88, 0.12, 0.08))

	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-30, -39), "EL ENGENDRO",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.35, 0.15, 0.9))

extends Control

# Guided tutorial: each step sets up a small scenario, shows an instruction
# card, waits for the player to demonstrate the mechanic, then advances.
# main.gd creates an instance, calls start(main), and forwards notify_* events.

signal finished

const LARVA_SCENE = preload("res://scenes/larva.tscn")

enum Step {
	MOVE,
	SHOOT,
	DASH,
	GRENADE,
	STRATAGEM_SUPPLY,
	ORDERS,
	MEDIC_CALL,
	STRATAGEM_AIRSTRIKE,
	LASER,
}

const STEP_INFO: Dictionary = {
	Step.MOVE: {
		"title": "1 / 9   MOVIMIENTO",
		"body":  "Usá WASD para moverte. Llegá al marcador verde.",
	},
	Step.SHOOT: {
		"title": "2 / 9   DISPARO",
		"body":  "Apuntá con el mouse, click IZQUIERDO para disparar. Eliminá los 3 enemigos.\nR recarga el cargador.",
	},
	Step.DASH: {
		"title": "3 / 9   DASH",
		"body":  "SPACE = dash en la dirección de movimiento. Hacé un dash para continuar.",
	},
	Step.GRENADE: {
		"title": "4 / 9   GRANADA",
		"body":  "Click DERECHO en el centro del grupo lanza una granada explosiva.\nEliminá el grupo (idealmente con una sola).",
	},
	Step.STRATAGEM_SUPPLY: {
		"title": "5 / 9   ESTRATAGEMA — SUPPLY",
		"body":  "Apretá TAB, después tipeá ↑↑↓↓ con las flechas.\nDespués click donde quieras que caiga el drop.",
	},
	Step.ORDERS: {
		"title": "6 / 9   ÓRDENES AL ESCUADRÓN",
		"body":  "Apretá V y después click donde quieras juntar a tus NPCs.",
	},
	Step.MEDIC_CALL: {
		"title": "7 / 9   LLAMAR AL MÉDICO",
		"body":  "Apretá H. El médico viene a tu posición ya.",
	},
	Step.STRATAGEM_AIRSTRIKE: {
		"title": "8 / 9   ESTRATAGEMA — AIRSTRIKE",
		"body":  "TAB, después ←↑→↓ con las flechas. Click sobre el grupo y caen 5 explosiones en línea.",
	},
	Step.LASER: {
		"title": "9 / 9   LÁSER ORBITAL",
		"body":  "Apretá L, después click sobre el grupo. 2.4s después cae el rayo.\nMirá el HUD: tenés 2 cargas.",
	},
}

var _main: Node = null
var _idx: int = 0
var _spawned: Array = []
var _marker_pos: Vector2 = Vector2.ZERO
var _marker_active: bool = false
var _enter_step_t: float = 0.0
var _kills_in_step: int = 0
var _grenade_in_step: bool = false
var _supply_in_step: bool = false
var _airstrike_in_step: bool = false
var _orders_in_step: bool = false
var _medic_called_in_step: bool = false
var _laser_in_step: bool = false
var _dash_in_step: bool = false
var _last_dash_cd: float = 0.0

# UI
var _card: Panel
var _title_lbl: Label
var _body_lbl: Label
var _toast: Label


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	anchor_right  = 1.0
	anchor_bottom = 1.0
	z_index = 80
	_build_ui()


func _build_ui() -> void:
	# Anchor card to TOP-CENTER so it doesn't overlap the left-side HUD stats
	_card = Panel.new()
	_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_card.size     = Vector2(460, 110)
	_card.position = Vector2(-230, 18)
	_card.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_card)

	_title_lbl = Label.new()
	_title_lbl.size     = Vector2(440, 24)
	_title_lbl.position = Vector2(14, 8)
	_title_lbl.add_theme_font_size_override("font_size", 16)
	_title_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	_card.add_child(_title_lbl)

	_body_lbl = Label.new()
	_body_lbl.size     = Vector2(440, 76)
	_body_lbl.position = Vector2(14, 30)
	_body_lbl.add_theme_font_size_override("font_size", 12)
	_body_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.85))
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card.add_child(_body_lbl)

	# Toast appears mid-screen
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.size     = Vector2(640, 36)
	_toast.position = Vector2(-320, -18)
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.visible = false
	add_child(_toast)


func start(main: Node) -> void:
	_main = main
	_begin_step()


func _begin_step() -> void:
	_clear_spawned()
	_marker_active = false
	_enter_step_t  = 0.0
	_kills_in_step = 0
	_grenade_in_step = false
	_supply_in_step = false
	_airstrike_in_step = false
	_orders_in_step = false
	_medic_called_in_step = false
	_laser_in_step = false
	_dash_in_step = false
	if _idx >= STEP_INFO.size():
		_finish()
		return
	var info: Dictionary = STEP_INFO[_idx]
	_title_lbl.text = info["title"]
	_body_lbl.text  = info["body"]
	_setup_step()
	queue_redraw()


func _setup_step() -> void:
	match _idx:
		Step.MOVE:
			_marker_pos = _main.BASE_POS + Vector2(220.0, -120.0)
			_marker_active = true
		Step.SHOOT:
			_spawn_enemies_at_offsets([
				Vector2(280, -80),
				Vector2(280,   0),
				Vector2(280,  80),
			])
		Step.DASH:
			pass  # just listen for dash
		Step.GRENADE:
			_spawn_enemies_at_offsets([
				Vector2(280, -25),
				Vector2(310,  10),
				Vector2(290,  40),
				Vector2(265,  -5),
				Vector2(320, -40),
			])
		Step.STRATAGEM_SUPPLY:
			pass
		Step.ORDERS:
			pass
		Step.MEDIC_CALL:
			# Reduce player HP a bit so the call has meaning
			if is_instance_valid(_main._player):
				_main._player.hp = mini(_main._player.hp, 45)
		Step.STRATAGEM_AIRSTRIKE:
			# Spawn a line of enemies
			var pts: Array = []
			for i in 8:
				pts.append(Vector2(320 + (i - 3) * 12.0, -80 + i * 20.0))
			_spawn_enemies_at_offsets(pts)
		Step.LASER:
			# Tight cluster
			var pts: Array = []
			for i in 10:
				pts.append(Vector2(320 + randf_range(-40, 40), randf_range(-40, 40)))
			_spawn_enemies_at_offsets(pts)


func _spawn_enemies_at_offsets(offsets: Array) -> void:
	if not is_instance_valid(_main._enemies):
		return
	for off in offsets:
		var e := LARVA_SCENE.instantiate()
		e.position         = _main.BASE_POS + off
		e.player           = _main._player
		e.base_pos         = _main.BASE_POS
		e.bullet_container = _main._bullets
		if "fortress" in e:
			e.fortress = _main._fortress
		e.died.connect(_main._on_enemy_died)
		_main._enemies.add_child(e)
		_spawned.append(e)


func _clear_spawned() -> void:
	for e in _spawned:
		if is_instance_valid(e):
			e.queue_free()
	_spawned.clear()


func _process(delta: float) -> void:
	if _main == null or not is_instance_valid(_main):
		return
	_enter_step_t += delta

	# Dash detection: watch player._dash_cd transition
	if is_instance_valid(_main._player):
		var cd: float = _main._player.get("_dash_cd") if "_dash_cd" in _main._player else 0.0
		if cd > _last_dash_cd + 0.5:
			_dash_in_step = true
		_last_dash_cd = cd

	if _is_step_done():
		_advance()


func _is_step_done() -> bool:
	match _idx:
		Step.MOVE:
			if is_instance_valid(_main._player):
				return _main._player.global_position.distance_to(_marker_pos) < 40.0
		Step.SHOOT:
			return _all_spawned_dead() and _enter_step_t > 0.5
		Step.DASH:
			return _dash_in_step
		Step.GRENADE:
			return _grenade_in_step and _all_spawned_dead()
		Step.STRATAGEM_SUPPLY:
			return _supply_in_step
		Step.ORDERS:
			return _orders_in_step
		Step.MEDIC_CALL:
			return _medic_called_in_step
		Step.STRATAGEM_AIRSTRIKE:
			return _airstrike_in_step and _all_spawned_dead()
		Step.LASER:
			return _laser_in_step and _all_spawned_dead()
	return false


func _all_spawned_dead() -> bool:
	var alive: int = 0
	for e in _spawned:
		if is_instance_valid(e):
			alive += 1
	return alive == 0


func _advance() -> void:
	_show_toast("✓  PASO COMPLETADO")
	var tree := get_tree()
	_idx += 1
	await tree.create_timer(1.2).timeout
	if not is_instance_valid(self):
		return
	_begin_step()


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_toast.visible = true
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(0.85)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.20)
	tw.tween_callback(func() -> void:
		_toast.visible = false)


func _finish() -> void:
	_show_toast("¡TUTORIAL TERMINADO!")
	_title_lbl.text = "LIBRE"
	_body_lbl.text  = "Ya conocés todas las mecánicas. Seguí practicando o salí con ESC."
	finished.emit()


# ─── Notifications from main.gd ──────────────────────────────────────────────

func notify_enemy_killed(_e: Node) -> void:
	_kills_in_step += 1


func notify_grenade_exploded() -> void:
	_grenade_in_step = true


func notify_stratagem_landed(type: int) -> void:
	if type == 0:   # StratagemDrop.Type.SUPPLY
		_supply_in_step = true
	elif type == 2: # AIRSTRIKE
		_airstrike_in_step = true


func notify_orders_issued() -> void:
	_orders_in_step = true


func notify_medic_called() -> void:
	_medic_called_in_step = true


func notify_laser_fired() -> void:
	_laser_in_step = true


# ─── Draw the marker for MOVE step ───────────────────────────────────────────
# Marker is drawn at world coordinates via a child Node2D so it appears
# under the camera. We use a small helper child to draw it.


func _draw() -> void:
	# Control._draw uses screen coords; the marker needs world coords, so we
	# render via the camera transform. Easiest: skip drawing here and use a
	# Node2D child created in _setup_step. For simplicity (and because the
	# MOVE step already shows position via instructions), we render an
	# on-screen arrow pointing toward the marker instead.
	if not _marker_active or not is_instance_valid(_main) \
			or not is_instance_valid(_main._player):
		return
	# Project player & marker into screen space
	var cam: Camera2D = _main._camera if "_camera" in _main else null
	if cam == null:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = vp_size * 0.5
	var offset: Vector2 = _marker_pos - cam.global_position
	var marker_screen: Vector2 = center + offset
	# Clamp to screen edge if offscreen, draw arrow
	var margin: float = 60.0
	if marker_screen.x < margin or marker_screen.x > vp_size.x - margin \
			or marker_screen.y < margin or marker_screen.y > vp_size.y - margin:
		marker_screen.x = clampf(marker_screen.x, margin, vp_size.x - margin)
		marker_screen.y = clampf(marker_screen.y, margin, vp_size.y - margin)
	# Pulsing ring
	var pulse: float = 0.5 + 0.5 * absf(sin(_enter_step_t * 5.0))
	draw_arc(marker_screen, 32.0, 0.0, TAU, 28,
		Color(0.55, 1.0, 0.65, pulse * 0.85), 4.0)
	draw_arc(marker_screen, 18.0, 0.0, TAU, 24,
		Color(0.55, 1.0, 0.65, 0.85), 2.0)


func _physics_process(_delta: float) -> void:
	# Force redraw of the marker arrow each tick
	if _marker_active:
		queue_redraw()

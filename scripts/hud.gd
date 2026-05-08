extends CanvasLayer

const TelegraphDisplay = preload("res://scripts/telegraph_display.gd")
const Minimap          = preload("res://scripts/minimap.gd")

signal build_type_selected(type: int)
signal upgrade_selected(type: int)

const VIEW_W := 1280.0
const VIEW_H := 720.0

const _UPG_INFO := [
	{"name": "VELOCIDAD", "max_lv": 3, "cost": 5,  "color": Color(0.40, 0.85, 1.00)},
	{"name": "ARMAMENTO", "max_lv": 3, "cost": 6,  "color": Color(1.00, 0.75, 0.20)},
	{"name": "BLINDAJE",  "max_lv": 2, "cost": 8,  "color": Color(0.60, 0.90, 0.60)},
	{"name": "CURACIÓN",  "max_lv": 1, "cost": 10, "color": Color(0.30, 1.00, 0.60)},
]

const _BUILD_INFO := [
	{"name": "MURO",      "cost": 3,  "key": "B", "color": Color(0.70, 0.90, 0.70)},
	{"name": "TORRETA",   "cost": 8,  "key": "T", "color": Color(1.00, 0.75, 0.20)},
	{"name": "MURO +",    "cost": 5,  "key": "N", "color": Color(0.50, 1.00, 0.55)},
	{"name": "MINA",      "cost": 3,  "key": "M", "color": Color(0.90, 0.50, 0.90)},
	{"name": "BARRICADA", "cost": 4,  "key": "C", "color": Color(0.85, 0.75, 0.45)},
]

var _hp_lbl:          Label
var _hp_bar_fill:     ColorRect
var _wave_lbl:        Label
var _kills_lbl:       Label
var _base_lbl:        Label
var _biomasa_lbl:     Label
var _weapon_lbl:      Label
var _ammo_lbl:        Label
var _bomb_lbl:        Label
var _grenade_lbl:     Label
var _announce_wave:   Label
var _announce_msg:    Label
var _go_panel:        Panel
var _go_reason:       Label
var _go_wave:         Label
var _go_kills:        Label
var _build_panel:     Panel
var _build_time_lbl:  Label
var _build_cards:     Array[Panel] = []
var _upg_panel:       Control
var _upg_cards:       Array[Panel] = []
var _upg_cost_lbls:   Array[Label] = []
var _telegraph:       Control
var _minimap:         Control
var _mission_lbl: Label
var _mission_bar: ColorRect
var _queen_lbl:   Label

var _elev_lbl:      Label
var _enemy_progress: Label
var _stair_prompt:  Label
var _max_hp:     int   = 100
var _infect_lbl: Label

const HP_BAR_W := 183.0

func _ready() -> void:
	_build()

func _build() -> void:
	# --- Stats panel ---
	var bg := Panel.new()
	bg.size     = Vector2(213, 280)
	bg.position = Vector2(10, 10)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(14, 10)
	bg.add_child(vbox)

	_hp_lbl = _lbl("HP: 100/100")
	vbox.add_child(_hp_lbl)

	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(HP_BAR_W, 10)
	vbox.add_child(bar_wrap)
	var bar_bg := ColorRect.new()
	bar_bg.size  = Vector2(HP_BAR_W, 8)
	bar_bg.color = Color(0.18, 0.04, 0.04)
	bar_wrap.add_child(bar_bg)
	_hp_bar_fill       = ColorRect.new()
	_hp_bar_fill.size  = Vector2(HP_BAR_W, 8)
	_hp_bar_fill.color = Color(0.2, 0.8, 0.2)
	bar_bg.add_child(_hp_bar_fill)

	_wave_lbl    = _lbl("MISIÓN: 0")
	_kills_lbl   = _lbl("KILLS: 0")
	_base_lbl    = _lbl("BASE: 1000")
	_biomasa_lbl = _lbl("CHATARRA: 0")
	_biomasa_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.55))
	_weapon_lbl  = _lbl("[ RIFLE ]")
	_weapon_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
	_ammo_lbl    = _lbl("30 / 30  ·  90", 16)
	_ammo_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	_elev_lbl    = _lbl("PISO: 0", 16)
	_elev_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95))
	vbox.add_child(_wave_lbl)
	vbox.add_child(_kills_lbl)
	vbox.add_child(_base_lbl)
	vbox.add_child(_biomasa_lbl)
	vbox.add_child(_weapon_lbl)
	vbox.add_child(_ammo_lbl)
	vbox.add_child(_elev_lbl)

	# Contador de enemigos de la wave actual — se posiciona debajo del HUD lateral
	_enemy_progress = _lbl("", 15)
	_enemy_progress.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	_enemy_progress.visible = false
	vbox.add_child(_enemy_progress)
	_bomb_lbl = _lbl("  BOMBA  —", 15)
	_bomb_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	_grenade_lbl = _lbl("  GRANADA  —", 15)
	_grenade_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	vbox.add_child(_bomb_lbl)
	vbox.add_child(_grenade_lbl)

	_infect_lbl = _lbl("", 14)
	_infect_lbl.add_theme_color_override("font_color", Color(0.75, 0.20, 1.0))
	_infect_lbl.visible = false
	vbox.add_child(_infect_lbl)

	# Upgrade panel will be created INSIDE the build panel below

	# --- Minimap (esquina superior derecha) ---
	_minimap          = Minimap.new()
	_minimap.position = Vector2(VIEW_W - 215, 14)
	add_child(_minimap)

	# --- Telegraph display ---
	_telegraph              = TelegraphDisplay.new()
	_telegraph.size         = Vector2(215, 162)
	_telegraph.position     = Vector2(VIEW_W - 225, 158)
	_telegraph.visible      = false
	_telegraph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_telegraph)

	# --- Wave announce ---
	_announce_wave = _lbl("", 50)
	_announce_wave.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_announce_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce_wave.size         = Vector2(640, 64)
	_announce_wave.position     = Vector2(320, 270)
	_announce_wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_announce_wave.visible      = false
	add_child(_announce_wave)

	_announce_msg = _lbl("", 19)
	_announce_msg.add_theme_color_override("font_color", Color(0.78, 0.92, 0.78))
	_announce_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce_msg.size         = Vector2(640, 28)
	_announce_msg.position     = Vector2(320, 336)
	_announce_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_announce_msg.visible      = false
	add_child(_announce_msg)

	# --- Build + Upgrades unified panel (bottom action bar) ---
	_build_panel          = Panel.new()
	_build_panel.size     = Vector2(760, 202)
	_build_panel.position = Vector2(260, 514)
	_build_panel.visible  = false
	add_child(_build_panel)

	_build_time_lbl = _lbl("CONSTRUCCIÓN  15s", 18)
	_build_time_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
	_build_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_time_lbl.size         = Vector2(760, 24)
	_build_time_lbl.position     = Vector2(0, 5)
	_build_time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_panel.add_child(_build_time_lbl)

	# Build cards row
	var card_w := 141.0
	var card_h := 62.0
	var card_x := 10.0
	var gap    := 8.0
	for i in _BUILD_INFO.size():
		var info: Dictionary = _BUILD_INFO[i]
		var card := Panel.new()
		card.size     = Vector2(card_w, card_h)
		card.position = Vector2(card_x + i * (card_w + gap), 32)
		_build_panel.add_child(card)
		_build_cards.append(card)

		var name_lbl := _lbl("[%s]  %s" % [info["key"], info["name"]], 16)
		name_lbl.add_theme_color_override("font_color", info["color"])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.size         = Vector2(card_w, 26)
		name_lbl.position     = Vector2(0, 6)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_lbl)

		var cost_lbl := _lbl("%d chatarra" % info["cost"], 13)
		cost_lbl.add_theme_color_override("font_color", Color(0.70, 0.85, 0.70))
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.size         = Vector2(card_w, 20)
		cost_lbl.position     = Vector2(0, 36)
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cost_lbl)

		var bidx := i
		card.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed \
					and event.button_index == MOUSE_BUTTON_LEFT:
				build_type_selected.emit(bidx))

	# Divider line between build and upgrade rows
	var divider := ColorRect.new()
	divider.size         = Vector2(740, 1)
	divider.position     = Vector2(10, 101)
	divider.color        = Color(0.3, 0.3, 0.3, 0.5)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_panel.add_child(divider)

	# Upgrades section (inside build panel)
	_upg_panel          = Control.new()
	_upg_panel.size     = Vector2(760, 96)
	_upg_panel.position = Vector2(0, 103)
	_upg_panel.visible  = false
	_build_panel.add_child(_upg_panel)

	var utitle := _lbl("── MEJORAS ──", 12)
	utitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.45))
	utitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	utitle.size         = Vector2(760, 18)
	utitle.position     = Vector2(0, 2)
	utitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upg_panel.add_child(utitle)

	var upg_w := 172.0
	for i in _UPG_INFO.size():
		var info: Dictionary = _UPG_INFO[i]
		var card := Panel.new()
		card.size     = Vector2(upg_w, 58)
		card.position = Vector2(card_x + i * (upg_w + gap), 22)
		_upg_panel.add_child(card)
		_upg_cards.append(card)

		var name_lbl := _lbl(info["name"], 14)
		name_lbl.add_theme_color_override("font_color", info["color"])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.size         = Vector2(upg_w, 24)
		name_lbl.position     = Vector2(0, 5)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_lbl)

		var cost_lbl := _lbl("", 11)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.size         = Vector2(upg_w, 18)
		cost_lbl.position     = Vector2(0, 32)
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cost_lbl)
		_upg_cost_lbls.append(cost_lbl)

		var uidx := i
		card.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed \
					and event.button_index == MOUSE_BUTTON_LEFT:
				upgrade_selected.emit(uidx))

	var hint := _lbl("[Clic-der] Reparar(2)  ·  [ENTER] Iniciar misión", 12)
	hint.add_theme_color_override("font_color", Color(0.55, 0.68, 0.55))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size         = Vector2(760, 18)
	hint.position     = Vector2(0, 182)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_panel.add_child(hint)

	_mission_lbl = Label.new()  # placeholder — no mission panel
	_mission_bar = ColorRect.new()
	_queen_lbl   = Label.new()

	# --- Stair prompt (flotante, centro-bajo de pantalla) ---
	_stair_prompt = _lbl("[E] Subir", 18)
	_stair_prompt.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_stair_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_stair_prompt.add_theme_constant_override("outline_size", 4)
	_stair_prompt.size                 = Vector2(260, 30)
	_stair_prompt.position             = Vector2(VIEW_W * 0.5 - 130, VIEW_H * 0.5 + 60)
	_stair_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stair_prompt.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	_stair_prompt.visible              = false
	add_child(_stair_prompt)

	# --- Game Over panel ---
	_go_panel          = Panel.new()
	_go_panel.size     = Vector2(460, 310)
	_go_panel.position = Vector2(410, 205)
	_go_panel.visible  = false
	add_child(_go_panel)

	var gv := VBoxContainer.new()
	gv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	_go_panel.add_child(gv)

	var title := _lbl("GAME OVER", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(title)
	gv.add_child(_spacer(6))

	_go_reason = _lbl("", 20)
	_go_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_go_reason.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	gv.add_child(_go_reason)
	gv.add_child(_spacer(10))

	_go_wave = _lbl("", 22)
	_go_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(_go_wave)

	_go_kills = _lbl("", 22)
	_go_kills.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(_go_kills)
	gv.add_child(_spacer(16))

	var btn := Button.new()
	btn.text = "REINICIAR  [R]"
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(_restart)
	gv.add_child(btn)

func _lbl(text: String, size: int = 18) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _unhandled_input(event: InputEvent) -> void:
	if _go_panel.visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			_restart()

func update_hp(v: int) -> void:
	_hp_lbl.text = "HP: %d/%d" % [v, _max_hp]
	var r := float(v) / float(_max_hp)
	_hp_bar_fill.size.x = HP_BAR_W * r
	_hp_bar_fill.color  = (Color(0.2, 0.8, 0.2) if v > _max_hp * 0.5
	                  else Color(0.85, 0.72, 0.1) if v > _max_hp * 0.25
	                  else Color(0.9, 0.12, 0.12))

func update_max_hp(v: int) -> void:
	_max_hp = v

func update_wave(v: int)     -> void: _wave_lbl.text  = "MISIÓN: %d" % v
func update_kills(v: int)    -> void: _kills_lbl.text = "KILLS: %d" % v

func update_enemy_progress(killed: int, total: int) -> void:
	if total <= 0:
		_enemy_progress.visible = false
		return
	_enemy_progress.visible = true
	var pct := float(killed) / float(total)
	var bar_len := 12
	var filled  := int(pct * bar_len)
	var bar     := ("█".repeat(filled) if filled > 0 else "") + ("░".repeat(bar_len - filled) if bar_len - filled > 0 else "")
	_enemy_progress.text = "%d/%d  %s" % [killed, total, bar]
	if pct >= 0.8:
		_enemy_progress.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	elif pct >= 0.5:
		_enemy_progress.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	else:
		_enemy_progress.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

func update_base_hp(v: int) -> void:
	_base_lbl.text = "BASE: %d" % v
	_base_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.3, 0.3) if v < 400 else Color(1.0, 1.0, 1.0))

func update_weapon(wname: String) -> void:
	_weapon_lbl.text = "[ %s ]" % wname

func update_biomasa(v: int) -> void:
	_biomasa_lbl.text = "CHATARRA: %d" % v

func update_ammo(_wname: String, mag: int, mag_max: int, reserve: int, _reserve_max: int, reloading: bool) -> void:
	if reloading:
		_ammo_lbl.text = "RECARGANDO..."
		_ammo_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		return
	if mag == 0 and reserve == 0:
		_ammo_lbl.text = "SIN MUNICIÓN"
		_ammo_lbl.add_theme_color_override("font_color", Color(0.95, 0.20, 0.20))
		return
	if mag == 0:
		_ammo_lbl.text = "VACÍO  [R] recargar"
		_ammo_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.20))
		return
	_ammo_lbl.text = "%d / %d  ·  %d" % [mag, mag_max, reserve]
	var ratio := float(mag) / float(mag_max)
	if ratio > 0.5:
		_ammo_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	elif ratio > 0.25:
		_ammo_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25))
	else:
		_ammo_lbl.add_theme_color_override("font_color", Color(1.0, 0.40, 0.30))

func update_build_selection(type_name: String, _cost: int) -> void:
	for i in _build_cards.size():
		var info: Dictionary = _BUILD_INFO[i]
		if not type_name.is_empty() and info["name"] == type_name:
			_build_cards[i].modulate = Color(1.6, 1.6, 1.0)
		else:
			_build_cards[i].modulate = Color(1.0, 1.0, 1.0, 0.65)

func show_build_phase(seconds: int) -> void:
	_build_panel.visible = true
	_build_time_lbl.text = "CONSTRUCCIÓN  %ds" % seconds
	update_build_selection("", 0)

func update_build_timer(seconds: int) -> void:
	_build_time_lbl.text = "CONSTRUCCIÓN  %ds" % seconds

func hide_build_phase() -> void:
	_build_panel.visible = false

func show_upgrades(speed_lv: int, fire_lv: int, armor_lv: int, healed: bool, chatarra: int) -> void:
	_upg_panel.visible = true
	update_upgrades(speed_lv, fire_lv, armor_lv, healed, chatarra)

func hide_upgrades() -> void:
	_upg_panel.visible = false

func update_upgrades(speed_lv: int, fire_lv: int, armor_lv: int, healed: bool, chatarra: int) -> void:
	var levels  := [speed_lv, fire_lv, armor_lv, 0]
	var blocked := [false, false, false, healed]
	for i in _UPG_INFO.size():
		var info:  Dictionary = _UPG_INFO[i]
		var lv:    int = levels[i]
		var maxlv: int = int(info["max_lv"])
		var cost:  int = int(info["cost"])
		var card:  Panel = _upg_cards[i]
		var clbl:  Label = _upg_cost_lbls[i]
		if blocked[i] or lv >= maxlv:
			card.modulate = Color(1.0, 1.0, 1.0, 0.30)
			clbl.text = "usada" if blocked[i] else "MAX"
			clbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		elif chatarra >= cost:
			card.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var lv_str := "" if maxlv == 1 else "Nv.%d/%d  " % [lv, maxlv]
			clbl.text = "%s%d chatarra" % [lv_str, cost]
			clbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.55))
		else:
			card.modulate = Color(1.0, 1.0, 1.0, 0.50)
			var lv_str := "" if maxlv == 1 else "Nv.%d/%d  " % [lv, maxlv]
			clbl.text = "%s%d chatarra" % [lv_str, cost]
			clbl.add_theme_color_override("font_color", Color(0.75, 0.3, 0.3))

func announce_wave(n: int, msg: String = "") -> void:
	_announce_wave.text    = "── MISIÓN %d ──" % n
	_announce_msg.text     = msg
	_announce_wave.visible = true
	_announce_msg.visible  = msg != ""
	_announce_wave.scale   = Vector2(0.5, 0.5)
	_announce_wave.modulate.a = 0.0
	_announce_msg.modulate.a  = 0.0
	var tw := create_tween()
	tw.tween_property(_announce_wave, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_announce_wave, "scale", Vector2(1.0, 1.0), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_announce_msg, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.2)
	tw.tween_property(_announce_wave, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(_announce_msg, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		_announce_wave.visible = false
		_announce_msg.visible  = false)

func show_npc_announcement(role_name: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = "▼  %s DESPLEGADO  ▼" % role_name
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", color)
	lbl.size                 = Vector2(VIEW_W, 30)
	lbl.position             = Vector2(0, VIEW_H * 0.5 + 80)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	lbl.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.4)
	tw.tween_interval(2.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lbl.queue_free)

func show_telegraph(wave: int, pattern_name: String, spawns: Dictionary, enemy_count: int) -> void:
	_telegraph.set_data(wave, pattern_name, spawns, enemy_count)
	_telegraph.visible    = true
	_telegraph.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_telegraph, "modulate:a", 1.0, 0.4)

func hide_telegraph() -> void:
	_telegraph.visible = false

func update_bomb(count: int) -> void:
	if count > 0:
		_bomb_lbl.text = "◉ BOMBA  [Q]  x%d" % count
		_bomb_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.15))
	else:
		_bomb_lbl.text = "  BOMBA  —"
		_bomb_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))

func update_grenade(count: int, active: bool) -> void:
	if count > 0:
		var tag := "  ◈ GRANADA [G]+click  x%d" % count if active else "◉ GRANADA  [G]  x%d" % count
		_grenade_lbl.text = tag
		var col := Color(0.75, 1.0, 0.20) if active else Color(0.55, 0.75, 0.20)
		_grenade_lbl.add_theme_color_override("font_color", col)
	else:
		_grenade_lbl.text = "  GRANADA  —"
		_grenade_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))

func init_minimap(p: Node2D, en: Node2D, fr: Node2D, base: Vector2, m_w: float, m_h: float) -> void:
	_minimap.init(p, en, fr, base, m_w, m_h)

func set_minimap_visible(v: bool) -> void:
	_minimap.visible = v

func set_satellite_revealed(v: bool) -> void:
	_minimap.set_satellite_revealed(v)

func set_minimap_threat(dir: Vector2) -> void:
	_minimap.set_threat_dir(dir)

func set_crates_node(node: Node2D) -> void:
	_minimap.set_crates_node(node)

func show_game_over(wave: int, kills: int, base_destroyed: bool = false) -> void:
	_go_reason.text     = "¡BASE DESTRUIDA!" if base_destroyed else "SOLDADO CAÍDO"
	_go_wave.text       = "Wave alcanzada: %d" % wave
	_go_kills.text      = "Kills: %d"          % kills
	_go_panel.visible   = true
	_go_panel.modulate  = Color(1, 1, 1, 0)
	_go_panel.scale     = Vector2(0.7, 0.7)
	_go_panel.pivot_offset = _go_panel.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_go_panel, "modulate:a", 1.0, 0.45)
	tw.tween_property(_go_panel, "scale", Vector2.ONE, 0.40)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_infected(v: bool) -> void:
	if not _infect_lbl:
		return
	_infect_lbl.visible = v
	if v:
		_infect_lbl.text = "⚠  INFECTADO"
	else:
		_infect_lbl.text = ""

func update_elevation(level: int) -> void:
	_elev_lbl.text = "PISO: %d" % level
	var col := Color(0.55, 0.75, 0.95)
	if level == 1:
		col = Color(0.45, 0.85, 0.55)
	elif level == 2:
		col = Color(0.95, 0.85, 0.30)
	elif level == 3:
		col = Color(1.0, 0.55, 0.20)
	_elev_lbl.add_theme_color_override("font_color", col)

func show_stair_prompt(can_climb: bool, target_level: int, current_level: int) -> void:
	if not can_climb:
		_stair_prompt.visible = false
		return
	var direction := "Subir" if target_level > current_level else "Bajar"
	_stair_prompt.text    = "[E] %s al piso %d" % [direction, target_level]
	_stair_prompt.visible = true

func set_queen_alert(_on: bool, _countdown: int = 0) -> void:
	pass

func _restart() -> void:
	get_tree().reload_current_scene()

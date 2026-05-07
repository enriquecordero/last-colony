extends Control

const MissionData = preload("res://scripts/mission_data.gd")

const VIEW_W := 1280.0
const VIEW_H  := 720.0
const CARD_W  := 240.0
const CARD_H  := 112.0

const _POSITIONS: Dictionary = {
	"stage1_recon":         Vector2(640, 145),
	"stage1_satellite":     Vector2(370, 292),
	"stage1_research":      Vector2(910, 292),
	"stage1_extermination": Vector2(640, 440),
	"stage1_engendro":      Vector2(640, 575),
}

const _CONNECTIONS: Array = [
	["stage1_recon",         "stage1_satellite"],
	["stage1_recon",         "stage1_research"],
	["stage1_satellite",     "stage1_extermination"],
	["stage1_research",      "stage1_extermination"],
	["stage1_extermination", "stage1_engendro"],
]

const COL_AVAILABLE := Color(0.25, 0.82, 0.42)
const COL_COMPLETED := Color(0.30, 0.75, 1.00)
const COL_LOCKED    := Color(0.35, 0.35, 0.40)
const COL_SURVIVAL  := Color(0.95, 0.40, 0.20)
const COL_LINE      := Color(0.28, 0.42, 0.28, 0.65)

var _selected_id:      String     = ""
var _survival_confirm: bool      = false
var _card_panels:      Dictionary = {}
var _deploy_panel:     Panel      = null
var _deploy_name_lbl:  Label      = null
var _deploy_warn_lbl:  Label      = null
var _deploy_btn:       Button     = null
var _coop_btn:         Button     = null
var _meta_panel:       Panel      = null
var _chatarra_lbl:     Label      = null
var _meta_card_lbls:   Dictionary = {}

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.size  = Vector2(VIEW_W, VIEW_H)
	bg.color = Color(0.04, 0.04, 0.08)
	add_child(bg)

	var title := _lbl("◈  SECTOR ALPHA  ◈", 32, Color(0.3, 1.0, 0.42))
	title.size                 = Vector2(VIEW_W, 42)
	title.position             = Vector2(0, 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var sub := _lbl("Seleccioná una misión", 14, Color(0.45, 0.65, 0.45))
	sub.size                 = Vector2(VIEW_W, 22)
	sub.position             = Vector2(0, 62)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Chatarra banked display
	_chatarra_lbl = _lbl("CHATARRA: %d" % StageManager.chatarra_banked, 16, Color(0.3, 0.95, 0.55))
	_chatarra_lbl.size     = Vector2(220, 24)
	_chatarra_lbl.position = Vector2(VIEW_W - 230, 22)
	_chatarra_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_chatarra_lbl)

	# Mejoras button
	var meta_btn := Button.new()
	meta_btn.text = "⚙  MEJORAS"
	meta_btn.add_theme_font_size_override("font_size", 16)
	meta_btn.size     = Vector2(150, 38)
	meta_btn.position = Vector2(20, VIEW_H - 52)
	meta_btn.pressed.connect(_toggle_meta_panel)
	add_child(meta_btn)

	var missions := StageRegistry.get_stage_missions("stage1")
	for m in missions:
		_build_card(m)

	_build_deploy_panel()
	_build_meta_panel()
	queue_redraw()

func _build_card(mission) -> void:
	var status := StageManager.get_mission_status(mission.id)
	var center: Vector2 = _POSITIONS[mission.id]
	var col    := _status_color(status, mission.type)

	var card         := Panel.new()
	card.size         = Vector2(CARD_W, CARD_H)
	card.position     = center - Vector2(CARD_W * 0.5, CARD_H * 0.5)
	card.mouse_filter = MOUSE_FILTER_STOP
	add_child(card)
	_card_panels[mission.id] = card

	var tint         := ColorRect.new()
	tint.size         = Vector2(CARD_W, CARD_H)
	tint.color        = Color(col.r, col.g, col.b, 0.07)
	tint.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(tint)

	var bar         := ColorRect.new()
	bar.size         = Vector2(4, CARD_H)
	bar.color        = col
	bar.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(bar)

	var name_lbl := _lbl(mission.display_name.to_upper(), 16, col)
	name_lbl.size     = Vector2(CARD_W - 16, 26)
	name_lbl.position = Vector2(10, 10)
	card.add_child(name_lbl)

	var desc_lbl := _lbl(mission.description, 12, Color(0.70, 0.78, 0.70))
	desc_lbl.size          = Vector2(CARD_W - 16, 36)
	desc_lbl.position      = Vector2(10, 38)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(desc_lbl)

	if mission.reward_id != "":
		var rew := _lbl("+ " + _reward_str(mission.reward_id), 11, Color(0.85, 0.78, 0.28))
		rew.size     = Vector2(CARD_W - 16, 16)
		rew.position = Vector2(10, 74)
		card.add_child(rew)

	var footer   := "%s  %s" % [_type_str(mission.type), _status_str(status)]
	var foot_lbl := _lbl(footer, 11, Color(0.55, 0.55, 0.62))
	foot_lbl.size     = Vector2(CARD_W - 16, 18)
	foot_lbl.position = Vector2(10, 90)
	card.add_child(foot_lbl)

	if mission.is_optional:
		var opt := _lbl("OPCIONAL", 10, Color(0.78, 0.65, 0.28))
		opt.size     = Vector2(72, 16)
		opt.position = Vector2(CARD_W - 78, 10)
		card.add_child(opt)

	if status != "locked":
		var mid: String = mission.id
		card.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed \
					and event.button_index == MOUSE_BUTTON_LEFT:
				_select_mission(mid))

func _build_meta_panel() -> void:
	_meta_panel          = Panel.new()
	_meta_panel.size     = Vector2(780, 380)
	_meta_panel.position = Vector2((VIEW_W - 780) * 0.5, (VIEW_H - 380) * 0.5)
	_meta_panel.visible  = false
	add_child(_meta_panel)

	var title := _lbl("⚙  MEJORAS PERMANENTES", 22, Color(0.85, 0.90, 0.55))
	title.size                 = Vector2(780, 34)
	title.position             = Vector2(0, 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_panel.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.size     = Vector2(36, 30)
	close_btn.position = Vector2(736, 8)
	close_btn.pressed.connect(_toggle_meta_panel)
	_meta_panel.add_child(close_btn)

	var chatarra_row := _lbl("Chatarra disponible: %d" % StageManager.chatarra_banked, 15, Color(0.3, 0.95, 0.55))
	chatarra_row.size                 = Vector2(780, 22)
	chatarra_row.position             = Vector2(0, 46)
	chatarra_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_panel.add_child(chatarra_row)
	_meta_card_lbls["_chatarra_row"] = chatarra_row

	var keys    := StageManager.META_TREE.keys()
	var cols    := 3
	var card_w  := 228.0
	var card_h  := 100.0
	var pad_x   := 14.0
	var pad_y   := 76.0
	var gap_x   := 12.0
	var gap_y   := 12.0

	for i in keys.size():
		var key: String     = keys[i]
		var info: Dictionary = StageManager.META_TREE[key]
		var col_i: int = i % cols
		var row_i: int = floori(float(i) / float(cols))
		var cx: float = pad_x + col_i * (card_w + gap_x)
		var cy: float = pad_y + row_i * (card_h + gap_y)

		var card := Panel.new()
		card.size     = Vector2(card_w, card_h)
		card.position = Vector2(cx, cy)
		_meta_panel.add_child(card)

		var ic: Color = info["color"]
		var name_lbl := _lbl(info["label"], 15, ic)
		name_lbl.size                 = Vector2(card_w, 26)
		name_lbl.position             = Vector2(0, 8)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(name_lbl)

		var lv_lbl := _lbl("", 12, Color(0.75, 0.75, 0.75))
		lv_lbl.size                 = Vector2(card_w, 20)
		lv_lbl.position             = Vector2(0, 36)
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(lv_lbl)
		_meta_card_lbls[key + "_lv"] = lv_lbl

		var cost_lbl := _lbl("", 12, Color(0.3, 0.95, 0.55))
		cost_lbl.size                 = Vector2(card_w, 20)
		cost_lbl.position             = Vector2(0, 56)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(cost_lbl)
		_meta_card_lbls[key + "_cost"] = cost_lbl

		var buy_btn := Button.new()
		buy_btn.text = "COMPRAR"
		buy_btn.add_theme_font_size_override("font_size", 11)
		buy_btn.size     = Vector2(card_w - 20, 22)
		buy_btn.position = Vector2(10, 74)
		card.add_child(buy_btn)
		_meta_card_lbls[key + "_btn"] = buy_btn

		var k: String = key
		buy_btn.pressed.connect(func() -> void: _buy_meta(k))

	_refresh_meta_cards()


func _toggle_meta_panel() -> void:
	_meta_panel.visible = not _meta_panel.visible
	if _meta_panel.visible:
		_refresh_meta_cards()


func _buy_meta(key: String) -> void:
	if StageManager.buy_meta(key):
		_chatarra_lbl.text = "CHATARRA: %d" % StageManager.chatarra_banked
		_refresh_meta_cards()


func _refresh_meta_cards() -> void:
	var row_lbl: Label = _meta_card_lbls.get("_chatarra_row")
	if row_lbl:
		row_lbl.text = "Chatarra disponible: %d" % StageManager.chatarra_banked

	for key in StageManager.META_TREE.keys():
		var info: Dictionary = StageManager.META_TREE[key]
		var lv: int    = StageManager.get_meta_level(key)
		var max_lv: int = int(info["max"])
		var cost: int  = StageManager.get_meta_cost(key)

		var lv_lbl: Label  = _meta_card_lbls.get(key + "_lv")
		var cost_lbl: Label = _meta_card_lbls.get(key + "_cost")
		var buy_btn: Button = _meta_card_lbls.get(key + "_btn")
		if not lv_lbl or not cost_lbl or not buy_btn:
			continue

		lv_lbl.text = "Nivel %d / %d" % [lv, max_lv]
		if StageManager.is_meta_maxed(key):
			cost_lbl.text = "MÁXIMO"
			cost_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
			buy_btn.disabled = true
		else:
			cost_lbl.text = "%d chatarra" % cost
			var can_buy: bool = StageManager.chatarra_banked >= cost
			cost_lbl.add_theme_color_override("font_color",
				Color(0.3, 0.95, 0.55) if can_buy else Color(0.8, 0.3, 0.3))
			buy_btn.disabled = not can_buy


func _build_deploy_panel() -> void:
	_deploy_panel          = Panel.new()
	_deploy_panel.size     = Vector2(880, 78)
	_deploy_panel.position = Vector2((VIEW_W - 880) * 0.5, VIEW_H - 90)
	_deploy_panel.visible  = false
	add_child(_deploy_panel)

	_deploy_name_lbl = _lbl("", 18, Color(0.85, 0.95, 0.85))
	_deploy_name_lbl.size     = Vector2(500, 26)
	_deploy_name_lbl.position = Vector2(14, 8)
	_deploy_panel.add_child(_deploy_name_lbl)

	_deploy_warn_lbl = _lbl("", 12, COL_SURVIVAL)
	_deploy_warn_lbl.size     = Vector2(500, 20)
	_deploy_warn_lbl.position = Vector2(14, 38)
	_deploy_warn_lbl.visible  = false
	_deploy_panel.add_child(_deploy_warn_lbl)

	_deploy_btn          = Button.new()
	_deploy_btn.text     = "DESPLEGAR"
	_deploy_btn.add_theme_font_size_override("font_size", 17)
	_deploy_btn.size     = Vector2(160, 46)
	_deploy_btn.position = Vector2(526, 16)
	_deploy_btn.pressed.connect(_on_deploy_pressed)
	_deploy_panel.add_child(_deploy_btn)

	_coop_btn          = Button.new()
	_coop_btn.text     = "CO-OP ONLINE"
	_coop_btn.add_theme_font_size_override("font_size", 15)
	_coop_btn.size     = Vector2(160, 46)
	_coop_btn.position = Vector2(700, 16)
	_coop_btn.pressed.connect(_on_coop_pressed)
	_deploy_panel.add_child(_coop_btn)

func _select_mission(id: String) -> void:
	_selected_id       = id
	_survival_confirm  = false
	_update_highlights()
	_update_deploy_panel()

func _update_highlights() -> void:
	for mid in _card_panels:
		_card_panels[mid].modulate = Color(1.3, 1.3, 0.9) if mid == _selected_id \
				else Color(1.0, 1.0, 1.0)

func _update_deploy_panel() -> void:
	if _selected_id.is_empty():
		_deploy_panel.visible = false
		return
	var mission = StageRegistry.get_mission(_selected_id)
	if mission == null:
		_deploy_panel.visible = false
		return

	_deploy_name_lbl.text = mission.display_name.to_upper()
	_deploy_btn.text      = "DESPLEGAR"
	_deploy_btn.modulate  = Color.WHITE

	var is_survival: bool = (mission.type == MissionData.MissionType.SURVIVAL)
	_deploy_warn_lbl.visible = is_survival as bool
	if is_survival:
		_deploy_warn_lbl.text = "[!] SURVIVAL — si fallás perdés el progreso del Stage 1"

	_deploy_panel.visible = true

func _on_deploy_pressed() -> void:
	if _selected_id.is_empty():
		return
	var mission = StageRegistry.get_mission(_selected_id)
	if mission == null:
		return
	if mission.type == MissionData.MissionType.SURVIVAL and not _survival_confirm:
		_survival_confirm    = true
		_deploy_btn.text     = "¿CONFIRMAR?"
		_deploy_btn.modulate = Color(1.5, 0.6, 0.4)
		return
	_do_deploy()

func _do_deploy() -> void:
	StageManager.selected_mission_id = _selected_id
	StageManager.is_multiplayer = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_coop_pressed() -> void:
	if _selected_id.is_empty():
		return
	StageManager.selected_mission_id = _selected_id
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _draw() -> void:
	for pair in _CONNECTIONS:
		var a: Vector2 = _POSITIONS[pair[0]]
		var b: Vector2 = _POSITIONS[pair[1]]
		draw_line(a + Vector2(0, CARD_H * 0.5), b - Vector2(0, CARD_H * 0.5), COL_LINE, 2.0, true)

func _status_color(status: String, type: int) -> Color:
	if type == MissionData.MissionType.SURVIVAL and status != "locked":
		return COL_SURVIVAL
	match status:
		"available": return COL_AVAILABLE
		"completed": return COL_COMPLETED
		_:           return COL_LOCKED

func _type_str(type: int) -> String:
	match type:
		MissionData.MissionType.INCURSION: return "INCURSION"
		MissionData.MissionType.SURVIVAL:  return "[!] SURVIVAL"
		MissionData.MissionType.DEFEND:    return "DEFENSA"
		_:                                 return ""

func _status_str(status: String) -> String:
	match status:
		"available": return "· DISPONIBLE"
		"completed": return "· COMPLETADA"
		_:           return "· BLOQUEADA"

func _reward_str(reward_id: String) -> String:
	match reward_id:
		"full_minimap":    return "Mapa completo"
		"antiserum":       return "Suero antiinfeccion"
		"stage1_complete": return "Desbloquea Stage 2"
		_:                 return reward_id

func _lbl(text: String, sz: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", color)
	return l

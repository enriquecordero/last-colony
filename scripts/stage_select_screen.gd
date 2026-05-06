extends Control

const MissionData = preload("res://scripts/mission_data.gd")

const VIEW_W  := 1280.0
const VIEW_H  := 720.0
const CARD_W  := 240.0
const CARD_H  := 112.0

const _POSITIONS: Dictionary = {
	"stage1_recon":         Vector2(640, 148),
	"stage1_satellite":     Vector2(370, 305),
	"stage1_research":      Vector2(910, 305),
	"stage1_extermination": Vector2(640, 458),
	"stage1_engendro":      Vector2(640, 600),
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

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.size  = Vector2(VIEW_W, VIEW_H)
	bg.color = Color(0.04, 0.04, 0.08)
	add_child(bg)

	var title := _lbl("◈  SECTOR ALPHA  ◈", 32, Color(0.3, 1.0, 0.42))
	title.size                 = Vector2(VIEW_W, 42)
	title.position             = Vector2(0, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var sub := _lbl("Seleccioná una misión", 14, Color(0.45, 0.65, 0.45))
	sub.size                 = Vector2(VIEW_W, 22)
	sub.position             = Vector2(0, 72)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	var missions := StageRegistry.get_stage_missions("stage1")
	for m in missions:
		_build_card(m)

	queue_redraw()

func _build_card(mission: MissionData) -> void:
	var status := StageManager.get_mission_status(mission.id)
	var center: Vector2 = _POSITIONS[mission.id]
	var col    := _status_color(status, mission.type)

	var card         := Panel.new()
	card.size         = Vector2(CARD_W, CARD_H)
	card.position     = center - Vector2(CARD_W * 0.5, CARD_H * 0.5)
	card.mouse_filter = MOUSE_FILTER_STOP
	add_child(card)

	var tint       := ColorRect.new()
	tint.size       = Vector2(CARD_W, CARD_H)
	tint.color      = Color(col.r, col.g, col.b, 0.07)
	card.add_child(tint)

	var bar   := ColorRect.new()
	bar.size   = Vector2(4, CARD_H)
	bar.color  = col
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

func _draw() -> void:
	for pair in _CONNECTIONS:
		var a: Vector2 = _POSITIONS[pair[0]]
		var b: Vector2 = _POSITIONS[pair[1]]
		draw_line(a + Vector2(0, CARD_H * 0.5), b - Vector2(0, CARD_H * 0.5), COL_LINE, 2.0, true)

func _status_color(status: String, type: MissionData.MissionType) -> Color:
	if type == MissionData.MissionType.SURVIVAL and status != "locked":
		return COL_SURVIVAL
	match status:
		"available": return COL_AVAILABLE
		"completed": return COL_COMPLETED
		_:           return COL_LOCKED

func _type_str(type: MissionData.MissionType) -> String:
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

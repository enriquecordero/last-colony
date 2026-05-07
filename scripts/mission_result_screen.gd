extends Control

const VIEW_W := 1280.0
const VIEW_H  := 720.0

func _ready() -> void:
	_build()

func _build() -> void:
	var result  := StageManager.get_last_result()
	var success := bool(result.get("success", false))

	var bg := ColorRect.new()
	bg.size  = Vector2(VIEW_W, VIEW_H)
	bg.color = Color(0.04, 0.04, 0.08)
	add_child(bg)

	var panel          := Panel.new()
	panel.size          = Vector2(500, 320)
	panel.position      = Vector2((VIEW_W - 500) * 0.5, (VIEW_H - 320) * 0.5)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	panel.add_child(vbox)

	var col_title := Color(0.3, 1.0, 0.42) if success else Color(1.0, 0.3, 0.3)
	var txt_title := "MISIÓN COMPLETADA" if success else "MISIÓN FALLIDA"
	var title_lbl := _lbl(txt_title, 30, col_title)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	vbox.add_child(_spacer(14))

	var waves_lbl := _lbl("Oleadas:  %d" % int(result.get("waves", 0)), 20, Color(0.75, 0.85, 0.75))
	waves_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(waves_lbl)

	var kills_lbl := _lbl("Bajas:  %d" % int(result.get("kills", 0)), 20, Color(0.75, 0.85, 0.75))
	kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(kills_lbl)

	var chatarra := int(result.get("chatarra", 0))
	if success and chatarra > 0:
		vbox.add_child(_spacer(10))
		var rew_lbl := _lbl("+%d chatarra" % chatarra, 20, Color(0.3, 0.95, 0.55))
		rew_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(rew_lbl)

	var reward_id: String = result.get("reward_id", "")
	if success and reward_id != "":
		var rew2 := _lbl("+ " + _reward_str(reward_id), 16, Color(0.85, 0.78, 0.28))
		rew2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(rew2)

	if not success:
		vbox.add_child(_spacer(10))
		var reason_lbl := _lbl(_reason_str(result.get("reason", "")), 16, Color(0.85, 0.4, 0.4))
		reason_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(reason_lbl)

	vbox.add_child(_spacer(22))

	var btn := Button.new()
	btn.text = "VOLVER AL HUB"
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(_go_to_hub)
	vbox.add_child(btn)

func _go_to_hub() -> void:
	var result  := StageManager.get_last_result()
	var success := bool(result.get("success", false))
	if success:
		var chatarra := int(result.get("chatarra", 0))
		if chatarra > 0:
			StageManager.bank_chatarra(chatarra)
	StageManager.selected_mission_id = ""
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")

func _reward_str(rid: String) -> String:
	match rid:
		"full_minimap":    return "Mapa completo desbloqueado"
		"antiserum":       return "Suero antiinfeccion desbloqueado"
		"stage1_complete": return "Stage 2 desbloqueado"
		_:                 return rid

func _reason_str(reason: String) -> String:
	match reason:
		"player_died":     return "El soldado cayó en combate"
		"base_destroyed":  return "La base fue destruida"
		"survival_failed": return "La base fue destruida — progreso perdido"
		_:                 return "Misión fallida"

func _lbl(text: String, sz: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", color)
	return l

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

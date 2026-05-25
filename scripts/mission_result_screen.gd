extends Control

const VIEW_W := 1280.0
const VIEW_H  := 720.0

func _ready() -> void:
	_build()

func _build() -> void:
	var result    := StageManager.get_last_result()
	var success   := bool(result.get("success", false))
	var reward_id := result.get("reward_id", "") as String
	var is_finale := success and reward_id == "stage3_complete"
	var col_main  := Color(1.00, 0.85, 0.15) if is_finale \
		else (Color(0.30, 1.00, 0.42) if success else Color(1.00, 0.32, 0.32))
	MusicPlayer.set_mode(MusicPlayer.Mode.SILENT)

	# ── Background ────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.size  = Vector2(VIEW_W, VIEW_H)
	bg.color = Color(0.03, 0.04, 0.08)
	add_child(bg)

	var glow := ColorRect.new()
	glow.size  = Vector2(VIEW_W, VIEW_H)
	glow.color = Color(col_main.r * 0.06, col_main.g * 0.06, col_main.b * 0.06)
	add_child(glow)

	# ── Panel ─────────────────────────────────────────────────────────────────
	const PW := 600.0
	var panel := Panel.new()
	panel.size     = Vector2(PW, 500)
	panel.position = Vector2((VIEW_W - PW) * 0.5, (VIEW_H - 500) * 0.5)
	panel.modulate.a = 0.0
	add_child(panel)

	# Title
	var title_str := "◈  VICTORIA FINAL  ◈" if is_finale \
		else ("MISIÓN COMPLETADA" if success else "MISIÓN FALLIDA")
	var title_sz  := 42 if is_finale else 36
	var title_lbl := _lbl(title_str, title_sz, col_main)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size         = Vector2(PW, 52)
	title_lbl.position     = Vector2(0, 18)
	title_lbl.pivot_offset = Vector2(PW * 0.5, 26)
	title_lbl.scale        = Vector2(0.4, 0.4)
	title_lbl.modulate.a   = 0.0
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_lbl)

	# Separator
	var sep := ColorRect.new()
	sep.size     = Vector2(PW - 60, 1)
	sep.position = Vector2(30, 80)
	sep.color    = col_main.darkened(0.35)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep)

	# ── Stats grid (2 × 2) ────────────────────────────────────────────────────
	var waves    := int(result.get("waves",    0))
	var kills    := int(result.get("kills",    0))
	var time_sec := int(result.get("time_sec", 0))
	var chatarra := int(result.get("chatarra", 0))
	var min_t    := int(time_sec / 60)
	var sec_t    := int(time_sec) % 60

	var stats := [
		{"label": "OLEADAS",  "value": str(waves),
			"color": Color(0.55, 0.90, 1.00)},
		{"label": "BAJAS",    "value": str(kills),
			"color": Color(1.00, 0.80, 0.30)},
		{"label": "TIEMPO",   "value": "%d:%02d" % [min_t, sec_t],
			"color": Color(0.60, 0.85, 0.95)},
		{"label": "CHATARRA", "value": "+%d" % chatarra if success else "—",
			"color": Color(0.30, 0.95, 0.55)},
	]

	const CARD_W   := 252.0
	const CARD_H   := 74.0
	const GAP_X    := 16.0
	const GAP_Y    := 12.0
	const COLS     := 2
	var grid_w     := COLS * CARD_W + (COLS - 1) * GAP_X
	var sx         := (PW - grid_w) * 0.5
	const SY       := 94.0

	var stat_nodes: Array = []
	for i in stats.size():
		var info: Dictionary = stats[i]
		var col := int(i % COLS)
		var row := int(i / COLS)
		var cx  := sx + col * (CARD_W + GAP_X)
		var cy  := SY + row * (CARD_H + GAP_Y)

		var card := Panel.new()
		card.size       = Vector2(CARD_W, CARD_H)
		card.position   = Vector2(cx, cy)
		card.modulate.a = 0.0
		panel.add_child(card)
		stat_nodes.append(card)

		var name_lbl := _lbl(info["label"], 13, Color(0.60, 0.70, 0.60))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.size         = Vector2(CARD_W, 22)
		name_lbl.position     = Vector2(0, 8)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_lbl)

		var val_lbl := _lbl(info["value"], 28, info["color"])
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbl.size         = Vector2(CARD_W, 38)
		val_lbl.position     = Vector2(0, 30)
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(val_lbl)

	# ── Kill rate & extras ───────────────────────────────────────────────────
	var extra_y := SY + 2.0 * (CARD_H + GAP_Y) + 14.0
	var extra_nodes: Array = []

	if kills > 0 and time_sec > 0:
		var kpm  := float(kills) / maxf(float(time_sec) / 60.0, 0.1)
		var klbl := _lbl("%.1f bajas / min" % kpm, 15, Color(0.72, 0.72, 0.80))
		klbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		klbl.size         = Vector2(PW, 24)
		klbl.position     = Vector2(0, extra_y)
		klbl.modulate.a   = 0.0
		klbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(klbl)
		extra_nodes.append(klbl)
		extra_y += 30.0

	if success and reward_id != "":
		var rlbl := _lbl("✦  " + _reward_str(reward_id) + "  ✦", 16, Color(0.88, 0.78, 0.28))
		rlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rlbl.size         = Vector2(PW - 40, 26)
		rlbl.position     = Vector2(20, extra_y)
		rlbl.modulate.a   = 0.0
		rlbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(rlbl)
		extra_nodes.append(rlbl)
		extra_y += 34.0

	if not success:
		var flbl := _lbl(_reason_str(result.get("reason", "")), 17, Color(0.92, 0.36, 0.36))
		flbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flbl.size         = Vector2(PW - 40, 26)
		flbl.position     = Vector2(20, extra_y)
		flbl.modulate.a   = 0.0
		flbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(flbl)
		extra_nodes.append(flbl)
		extra_y += 34.0

	extra_y += 10.0

	# ── Button ────────────────────────────────────────────────────────────────
	var btn_text := "VER CRÉDITOS" if is_finale else "VOLVER AL HUB"
	var btn_w    := 220.0 if is_finale else 210.0
	var btn := Button.new()
	btn.text = btn_text
	btn.add_theme_font_size_override("font_size", 20)
	btn.size       = Vector2(btn_w, 46)
	btn.position   = Vector2((PW - btn_w) * 0.5, extra_y)
	btn.modulate.a = 0.0
	btn.pressed.connect(_go_to_hub)
	panel.add_child(btn)

	# Resize panel height
	panel.size.y   = extra_y + 60.0
	panel.position.y = (VIEW_H - panel.size.y) * 0.5

	# ── Animations ────────────────────────────────────────────────────────────
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel,     "modulate:a", 1.0,        0.25)
	tw.tween_property(title_lbl, "scale",      Vector2.ONE, 0.40)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(title_lbl, "modulate:a", 1.0,        0.30)

	var base_delay := 0.42
	for i in stat_nodes.size():
		var sn: Control = stat_nodes[i]
		var tw2 := create_tween()
		tw2.tween_interval(base_delay + i * 0.10)
		tw2.tween_property(sn, "modulate:a", 1.0, 0.22)

	var cur_delay := base_delay + stat_nodes.size() * 0.10 + 0.08
	for en in extra_nodes:
		var tw3 := create_tween()
		tw3.tween_interval(cur_delay)
		tw3.tween_property(en, "modulate:a", 1.0, 0.25)
		cur_delay += 0.14

	var tw4 := create_tween()
	tw4.tween_interval(cur_delay + 0.10)
	tw4.tween_property(btn, "modulate:a", 1.0, 0.35)


func _go_to_hub() -> void:
	var result    := StageManager.get_last_result()
	var success   := bool(result.get("success", false))
	var reward_id := result.get("reward_id", "") as String
	var is_finale := success and reward_id == "stage3_complete"
	if success:
		var chatarra := int(result.get("chatarra", 0))
		if chatarra > 0:
			StageManager.bank_chatarra(chatarra)
	StageManager.selected_mission_id = ""
	StageManager.is_tutorial = false
	if is_finale:
		get_tree().change_scene_to_file("res://scenes/credits.tscn")
	else:
		MusicPlayer.set_mode(MusicPlayer.Mode.MENU)
		get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


func _reward_str(rid: String) -> String:
	match rid:
		"full_minimap":    return "Mapa completo desbloqueado"
		"antiserum":       return "Suero antiinfeccion desbloqueado"
		"stage1_complete": return "Stage 2 desbloqueado"
		"stage2_complete": return "Stage 3 desbloqueado"
		"stage3_complete": return "¡VICTORIA FINAL — LA COLONIA SOBREVIVIÓ!"
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

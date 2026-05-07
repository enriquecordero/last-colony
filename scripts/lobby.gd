extends Control

const PORT        := 7777
const MAX_PLAYERS := 2
const MOVE_SPEED  := 160.0
const AREA_W      := 480.0
const AREA_H      := 260.0


# ── Inner draw node ───────────────────────────────────────────────────────────
class PlayArea extends Control:
	var p1_pos:  Vector2 = Vector2(120, 130)
	var p2_pos:  Vector2 = Vector2(360, 130)
	var p2_here: bool    = false

	func _draw() -> void:
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.06, 0.10, 0.06))
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.28, 0.50, 0.28, 0.5), false, 1.5)
		var f := ThemeDB.fallback_font
		# P1 — verde
		draw_circle(p1_pos, 13, Color(0.18, 0.82, 0.35))
		draw_arc(p1_pos, 13, 0, TAU, 24, Color(0.45, 1.0, 0.55), 1.5)
		draw_string(f, p1_pos + Vector2(-8, 4), "P1",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		# P2 — azul (o fantasma si no está)
		if p2_here:
			draw_circle(p2_pos, 13, Color(0.22, 0.50, 0.95))
			draw_arc(p2_pos, 13, 0, TAU, 24, Color(0.45, 0.70, 1.0), 1.5)
			draw_string(f, p2_pos + Vector2(-8, 4), "P2",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		else:
			draw_arc(Vector2(360, 130), 13, 0, TAU, 24, Color(0.4, 0.4, 0.5, 0.35), 1.5)
			draw_string(f, Vector2(353, 134), "?",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5, 0.5))


# ── Estado ────────────────────────────────────────────────────────────────────
var _phase:        String = "connecting"
var _p2_connected: bool   = false
var _selected_mid: String = ""

var _play_area: PlayArea

# UI — fase conexión
var _connect_root: Control
var _status_lbl:   Label
var _ip_field:     LineEdit
var _host_btn:     Button
var _join_btn:     Button

# UI — fase espera
var _wait_root:    Control
var _miss_sel_lbl: Label
var _start_btn:    Button
var _wait_info:    Label
var _p1_status:    Label
var _p2_status:    Label
var _miss_btns:    Dictionary = {}


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_selected_mid = StageManager.selected_mission_id
	_build_ui()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(delta: float) -> void:
	if _phase != "waiting" or not is_instance_valid(_play_area):
		return
	var is_host := multiplayer.is_server()
	var move := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	).normalized() * MOVE_SPEED * delta
	if move == Vector2.ZERO:
		return
	if is_host:
		_play_area.p1_pos = (_play_area.p1_pos + move).clamp(
			Vector2(14, 14), Vector2(AREA_W - 14, AREA_H - 14))
		_rpc_move.rpc(_play_area.p1_pos)
	else:
		_play_area.p2_pos = (_play_area.p2_pos + move).clamp(
			Vector2(14, 14), Vector2(AREA_W - 14, AREA_H - 14))
		_rpc_move.rpc(_play_area.p2_pos)
	_play_area.queue_redraw()


# ── UI ────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.08)
	add_child(bg)

	var title := _lbl("CO-OP ONLINE", 36, Color(0.3, 1.0, 0.42))
	title.size                 = Vector2(1280, 50)
	title.position             = Vector2(0, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	_build_connect_panel()
	_build_wait_panel()


func _build_connect_panel() -> void:
	_connect_root = Control.new()
	_connect_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_connect_root)

	var mid_lbl := _lbl("Misión: %s" % _mission_name(_selected_mid), 16, Color(0.65, 0.80, 0.65))
	mid_lbl.size                 = Vector2(1280, 28)
	mid_lbl.position             = Vector2(0, 72)
	mid_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_connect_root.add_child(mid_lbl)

	var panel     := Panel.new()
	panel.size     = Vector2(460, 310)
	panel.position = Vector2(410, 190)
	_connect_root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var ip_row := HBoxContainer.new()
	vbox.add_child(ip_row)
	var ip_lbl := _lbl("IP del host:", 15, Color(0.75, 0.85, 0.75))
	ip_lbl.custom_minimum_size = Vector2(120, 0)
	ip_row.add_child(ip_lbl)
	_ip_field = LineEdit.new()
	_ip_field.placeholder_text    = "127.0.0.1"
	_ip_field.text                = "127.0.0.1"
	_ip_field.custom_minimum_size = Vector2(200, 0)
	_ip_field.add_theme_font_size_override("font_size", 15)
	ip_row.add_child(_ip_field)

	_host_btn = Button.new()
	_host_btn.text = "HOSTEAR (crear partida)"
	_host_btn.add_theme_font_size_override("font_size", 16)
	_host_btn.custom_minimum_size = Vector2(0, 44)
	_host_btn.pressed.connect(_host)
	vbox.add_child(_host_btn)

	_join_btn = Button.new()
	_join_btn.text = "UNIRSE (conectar a IP)"
	_join_btn.add_theme_font_size_override("font_size", 16)
	_join_btn.custom_minimum_size = Vector2(0, 44)
	_join_btn.pressed.connect(_join)
	vbox.add_child(_join_btn)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(sep)

	_status_lbl = _lbl("Esperando...", 14, Color(0.75, 0.85, 0.75))
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status_lbl)

	var back := Button.new()
	back.text = "← VOLVER"
	back.add_theme_font_size_override("font_size", 14)
	back.custom_minimum_size = Vector2(0, 36)
	back.pressed.connect(_back)
	vbox.add_child(back)

	var info := _lbl(
		"Para probar en la misma máquina:\n" +
		"  1. Debug → Run Second Instance\n" +
		"  2. Instancia 1: HOSTEAR  |  Instancia 2: UNIRSE con 127.0.0.1\n\n" +
		"Para jugar online: el host comparte su IP y abre el puerto 7777 UDP.",
		12, Color(0.50, 0.60, 0.50))
	info.position             = Vector2(0, 540)
	info.size                 = Vector2(1280, 100)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_connect_root.add_child(info)


func _build_wait_panel() -> void:
	_wait_root         = Control.new()
	_wait_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wait_root.visible = false
	add_child(_wait_root)

	# ── Panel izquierdo: sala de espera ───────────────────────────────────────
	var left     := Panel.new()
	left.size     = Vector2(530, 540)
	left.position = Vector2(20, 90)
	_wait_root.add_child(left)

	var lh := _lbl("SALA DE ESPERA", 18, Color(0.3, 1.0, 0.42))
	lh.size                 = Vector2(530, 28)
	lh.position             = Vector2(0, 10)
	lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(lh)

	_play_area          = PlayArea.new()
	_play_area.size     = Vector2(AREA_W, AREA_H)
	_play_area.position = Vector2((530.0 - AREA_W) * 0.5, 50)
	left.add_child(_play_area)

	var hint := _lbl("Movete con WASD", 11, Color(0.45, 0.60, 0.45))
	hint.size                 = Vector2(530, 18)
	hint.position             = Vector2(0, 322)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(hint)

	_p1_status = _lbl("● Jugador 1 (host)  —  conectado", 14, Color(0.3, 1.0, 0.42))
	_p1_status.position = Vector2(20, 355)
	_p1_status.size     = Vector2(490, 22)
	left.add_child(_p1_status)

	_p2_status = _lbl("○ Jugador 2  —  esperando...", 14, Color(0.55, 0.55, 0.60))
	_p2_status.position = Vector2(20, 383)
	_p2_status.size     = Vector2(490, 22)
	left.add_child(_p2_status)

	var back_btn := Button.new()
	back_btn.text = "← VOLVER"
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.size     = Vector2(130, 34)
	back_btn.position = Vector2(20, 490)
	back_btn.pressed.connect(_back)
	left.add_child(back_btn)

	# ── Panel derecho: selección de misión ────────────────────────────────────
	var right     := Panel.new()
	right.size     = Vector2(690, 540)
	right.position = Vector2(570, 90)
	_wait_root.add_child(right)

	var rh := _lbl("MISIÓN", 18, Color(0.3, 1.0, 0.42))
	rh.size                 = Vector2(690, 28)
	rh.position             = Vector2(0, 10)
	rh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(rh)

	var note := _lbl("Solo el host puede cambiar la misión", 12, Color(0.50, 0.60, 0.50))
	note.size                 = Vector2(690, 18)
	note.position             = Vector2(0, 42)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(note)

	var missions := StageRegistry.get_stage_missions("stage1")
	var my       := 68.0
	for m in missions:
		var status := StageManager.get_mission_status(m.id)
		var btn    := Button.new()
		btn.text    = m.display_name.to_upper()
		btn.add_theme_font_size_override("font_size", 14)
		btn.size     = Vector2(640, 38)
		btn.position = Vector2(25, my)
		btn.disabled = (status == "locked")
		var mid_copy: String = m.id
		btn.pressed.connect(func() -> void: _on_mission_btn(mid_copy))
		right.add_child(btn)
		_miss_btns[m.id] = btn
		my += 46.0

	_miss_sel_lbl          = _lbl("Seleccionada: %s" % _mission_name(_selected_mid),
		15, Color(0.75, 0.90, 0.75))
	_miss_sel_lbl.position = Vector2(25, my + 10)
	_miss_sel_lbl.size     = Vector2(640, 24)
	right.add_child(_miss_sel_lbl)

	_start_btn = Button.new()
	_start_btn.text = "▶  INICIAR PARTIDA"
	_start_btn.add_theme_font_size_override("font_size", 18)
	_start_btn.size     = Vector2(640, 52)
	_start_btn.position = Vector2(25, my + 44)
	_start_btn.disabled = _selected_mid.is_empty()
	_start_btn.pressed.connect(_on_start_pressed)
	right.add_child(_start_btn)

	_wait_info = _lbl("Esperando que el host inicie...", 15, Color(0.60, 0.75, 0.60))
	_wait_info.size                 = Vector2(640, 52)
	_wait_info.position             = Vector2(25, my + 44)
	_wait_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wait_info.visible              = false
	right.add_child(_wait_info)

	_refresh_mission_btns()


# ── Helpers UI ────────────────────────────────────────────────────────────────

func _show_waiting(is_host: bool) -> void:
	_connect_root.visible = false
	_wait_root.visible    = true
	_phase                = "waiting"
	_play_area.p2_here    = _p2_connected
	_play_area.queue_redraw()
	_start_btn.visible    = is_host
	_wait_info.visible    = not is_host
	if not is_host:
		for btn in _miss_btns.values():
			(btn as Button).disabled = true


func _refresh_mission_btns() -> void:
	for mid in _miss_btns:
		var btn: Button = _miss_btns[mid]
		btn.modulate = Color(1.4, 1.4, 0.7) if mid == _selected_mid else Color.WHITE
	if is_instance_valid(_miss_sel_lbl):
		_miss_sel_lbl.text = "Seleccionada: %s" % _mission_name(_selected_mid)
	if is_instance_valid(_start_btn):
		_start_btn.disabled = _selected_mid.is_empty()


func _set_status(text: String, color: Color = Color(0.75, 0.85, 0.75)) -> void:
	if is_instance_valid(_status_lbl):
		_status_lbl.text = text
		_status_lbl.add_theme_color_override("font_color", color)


func _mission_name(mid: String) -> String:
	if mid.is_empty():
		return "—"
	var m = StageRegistry.get_mission(mid)
	return m.display_name if m != null else mid


func _lbl(text: String, sz: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", color)
	return l


# ── Conexión ──────────────────────────────────────────────────────────────────

func _host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err   := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		_set_status("Error al crear servidor (puerto %d ocupado?)" % PORT, Color(1, 0.3, 0.3))
		return
	multiplayer.multiplayer_peer = peer
	_host_btn.disabled = true
	_join_btn.disabled = true
	_set_status("Servidor iniciado en puerto %d\nEsperando jugador 2..." % PORT,
		Color(0.3, 1.0, 0.55))


func _join() -> void:
	var ip := _ip_field.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	var peer := ENetMultiplayerPeer.new()
	var err   := peer.create_client(ip, PORT)
	if err != OK:
		_set_status("Error al iniciar conexión", Color(1, 0.3, 0.3))
		return
	multiplayer.multiplayer_peer = peer
	_host_btn.disabled = true
	_join_btn.disabled = true
	_set_status("Conectando a %s:%d..." % [ip, PORT], Color(1.0, 0.85, 0.3))


func _back() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	StageManager.is_multiplayer = false
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


# ── Callbacks de red ──────────────────────────────────────────────────────────

func _on_peer_connected(_id: int) -> void:
	_p2_connected      = true
	_show_waiting(true)
	if is_instance_valid(_p2_status):
		_p2_status.text = "● Jugador 2  —  conectado"
		_p2_status.add_theme_color_override("font_color", Color(0.45, 0.70, 1.0))
	_rpc_set_mission.rpc(_selected_mid)


func _on_connected_to_server() -> void:
	_p2_connected = true
	_show_waiting(false)


func _on_connection_failed() -> void:
	_set_status("Conexión fallida. Verificá la IP y que el host esté esperando.",
		Color(1, 0.3, 0.3))
	_host_btn.disabled = false
	_join_btn.disabled = false
	multiplayer.multiplayer_peer = null


func _on_peer_disconnected(_id: int) -> void:
	_p2_connected = false
	if is_instance_valid(_play_area):
		_play_area.p2_here = false
		_play_area.queue_redraw()
	if is_instance_valid(_p2_status):
		_p2_status.text = "○ Jugador 2  —  se desconectó"
		_p2_status.add_theme_color_override("font_color", Color(1, 0.4, 0.3))


func _on_server_disconnected() -> void:
	_phase                = "connecting"
	_connect_root.visible = true
	_wait_root.visible    = false
	_host_btn.disabled    = false
	_join_btn.disabled    = false
	multiplayer.multiplayer_peer = null
	_set_status("Host desconectado.", Color(1, 0.3, 0.3))


# ── Selección de misión ───────────────────────────────────────────────────────

func _on_mission_btn(mid: String) -> void:
	if not multiplayer.is_server():
		return
	_selected_mid = mid
	_rpc_set_mission.rpc(mid)


func _on_start_pressed() -> void:
	if _selected_mid.is_empty():
		return
	_rpc_start_game.rpc()


# ── RPCs ──────────────────────────────────────────────────────────────────────

@rpc("any_peer", "unreliable_ordered")
func _rpc_move(pos: Vector2) -> void:
	if not is_instance_valid(_play_area):
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 1:
		_play_area.p1_pos = pos
	else:
		_play_area.p2_pos = pos
	_play_area.queue_redraw()


@rpc("authority", "call_local", "reliable")
func _rpc_set_mission(mid: String) -> void:
	_selected_mid = mid
	_refresh_mission_btns()


@rpc("authority", "call_local", "reliable")
func _rpc_start_game() -> void:
	StageManager.selected_mission_id = _selected_mid
	StageManager.is_multiplayer      = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

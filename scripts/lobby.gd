extends Control

const PORT        := 7777
const MAX_PLAYERS := 2

var _status_lbl: Label
var _ip_field:   LineEdit
var _host_btn:   Button
var _join_btn:   Button

func _ready() -> void:
	_build_ui()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.08)
	add_child(bg)

	var title := Label.new()
	title.text = "CO-OP ONLINE"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.42))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size     = Vector2(1280, 50)
	title.position = Vector2(0, 80)
	add_child(title)

	var mission_lbl := Label.new()
	var mid := StageManager.selected_mission_id
	mission_lbl.text = "Misión: %s" % (mid if mid != "" else "—")
	mission_lbl.add_theme_font_size_override("font_size", 16)
	mission_lbl.add_theme_color_override("font_color", Color(0.65, 0.80, 0.65))
	mission_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_lbl.size     = Vector2(1280, 30)
	mission_lbl.position = Vector2(0, 134)
	add_child(mission_lbl)

	# ── Panel central ──
	var panel          := Panel.new()
	panel.size          = Vector2(460, 300)
	panel.position      = Vector2(410, 200)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# IP row
	var ip_row := HBoxContainer.new()
	vbox.add_child(ip_row)

	var ip_lbl := Label.new()
	ip_lbl.text = "IP del host:"
	ip_lbl.add_theme_font_size_override("font_size", 15)
	ip_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75))
	ip_lbl.custom_minimum_size = Vector2(120, 0)
	ip_row.add_child(ip_lbl)

	_ip_field = LineEdit.new()
	_ip_field.placeholder_text  = "127.0.0.1"
	_ip_field.text              = "127.0.0.1"
	_ip_field.custom_minimum_size = Vector2(200, 0)
	_ip_field.add_theme_font_size_override("font_size", 15)
	ip_row.add_child(_ip_field)

	# Botones
	_host_btn      = Button.new()
	_host_btn.text = "HOSTEAR (crear partida)"
	_host_btn.add_theme_font_size_override("font_size", 16)
	_host_btn.custom_minimum_size = Vector2(0, 44)
	_host_btn.pressed.connect(_host)
	vbox.add_child(_host_btn)

	_join_btn      = Button.new()
	_join_btn.text = "UNIRSE (conectar a IP)"
	_join_btn.add_theme_font_size_override("font_size", 16)
	_join_btn.custom_minimum_size = Vector2(0, 44)
	_join_btn.pressed.connect(_join)
	vbox.add_child(_join_btn)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sep)

	_status_lbl = Label.new()
	_status_lbl.text = "Esperando..."
	_status_lbl.add_theme_font_size_override("font_size", 14)
	_status_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75))
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status_lbl)

	var back_btn      := Button.new()
	back_btn.text      = "← VOLVER"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.custom_minimum_size = Vector2(0, 36)
	back_btn.pressed.connect(_back)
	vbox.add_child(back_btn)

	# Instrucciones
	var info := Label.new()
	info.text = (
		"Para probar en la misma máquina:\n" +
		"  1. Abrí una segunda instancia: Debug → Run Second Instance\n" +
		"  2. Instancia 1: HOSTEAR  |  Instancia 2: UNIRSE con IP 127.0.0.1\n\n" +
		"Para jugar online: el host comparte su IP y abre el puerto 7777 UDP."
	)
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.50, 0.60, 0.50))
	info.position = Vector2(0, 540)
	info.size     = Vector2(1280, 100)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)


# ─────────────────────────────────────────────────────────────────────────────
# Conexión
# ─────────────────────────────────────────────────────────────────────────────

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
	# Limpiar peer si existe
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	StageManager.is_multiplayer = false
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


# ─────────────────────────────────────────────────────────────────────────────
# Callbacks de red
# ─────────────────────────────────────────────────────────────────────────────

func _on_peer_connected(id: int) -> void:
	_set_status("¡Jugador 2 conectado (id %d)! Iniciando partida..." % id,
		Color(0.3, 1.0, 0.42))
	# Enviamos la misión al cliente y luego cambiamos escena
	var mid := StageManager.selected_mission_id
	_rpc_load_game.rpc_id(id, mid)
	# Esperamos un frame para que el RPC salga antes de cambiar escena
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(self):
		return
	StageManager.is_multiplayer = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_connected_to_server() -> void:
	_set_status("Conectado al host. Esperando inicio...", Color(0.3, 1.0, 0.42))


func _on_connection_failed() -> void:
	_set_status("Conexión fallida. Verificá la IP y que el host esté esperando.",
		Color(1, 0.3, 0.3))
	_host_btn.disabled = false
	_join_btn.disabled = false
	multiplayer.multiplayer_peer = null


func _on_peer_disconnected(_id: int) -> void:
	_set_status("El otro jugador se desconectó.", Color(1, 0.6, 0.2))


func _on_server_disconnected() -> void:
	_set_status("Conexión con el host perdida.", Color(1, 0.3, 0.3))
	_host_btn.disabled = false
	_join_btn.disabled = false
	multiplayer.multiplayer_peer = null


# Llamada en el cliente para sincronizar misión y cambiar escena
@rpc("authority", "reliable")
func _rpc_load_game(mission_id: String) -> void:
	StageManager.selected_mission_id = mission_id
	StageManager.is_multiplayer      = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

func _set_status(text: String, color: Color = Color(0.75, 0.85, 0.75)) -> void:
	if is_instance_valid(_status_lbl):
		_status_lbl.text = text
		_status_lbl.add_theme_color_override("font_color", color)

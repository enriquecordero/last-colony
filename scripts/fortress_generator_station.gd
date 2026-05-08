extends CanvasLayer

signal biomasa_spent(amount: int)
signal station_activated
signal closed

const VIEW_W  := 1280.0
const VIEW_H  := 720.0
const COST    := 40

var _panel:      Panel
var _bank_lbl:   Label
var _status_lbl: Label
var _act_btn:    Button
var _biomasa:    int  = 0
var _active:     bool = false


func _ready() -> void:
	layer   = 23
	visible = false
	_build()


func open(biomasa: int, already_active: bool) -> void:
	_biomasa = biomasa
	_active  = already_active
	visible  = true
	_refresh()


func close() -> void:
	visible = false
	closed.emit()


func refresh_biomasa(amount: int) -> void:
	_biomasa = amount
	if visible:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_F:
			close()
			get_viewport().set_input_as_handled()


func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color        = Color(0, 0, 0, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	const PW := 420.0
	const PH := 320.0
	_panel          = Panel.new()
	_panel.size     = Vector2(PW, PH)
	_panel.position = Vector2((VIEW_W - PW) * 0.5, (VIEW_H - PH) * 0.5)
	add_child(_panel)

	var hdr := _lbl("◈  GENERADOR  ◈", 27, Color(0.30, 0.85, 1.0))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.size = Vector2(PW, 42); hdr.position = Vector2(0, 12)
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hdr)

	var sub := _lbl("Planta de energía — brazo oeste", 13, Color(0.45, 0.60, 0.68))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(PW, 20); sub.position = Vector2(0, 52)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(sub)

	_bank_lbl = _lbl("", 17, Color(0.30, 0.95, 0.55))
	_bank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bank_lbl.size = Vector2(PW, 24); _bank_lbl.position = Vector2(0, 74)
	_bank_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_bank_lbl)

	_add_sep(20.0, 102.0)

	_status_lbl = _lbl("", 20, Color.WHITE)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.size = Vector2(PW, 30); _status_lbl.position = Vector2(0, 114)
	_status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_status_lbl)

	var b1 := _lbl("  +15 chatarra por oleada completada", 14, Color(0.75, 0.90, 0.60))
	b1.size = Vector2(PW - 40.0, 20); b1.position = Vector2(20, 152)
	b1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(b1)

	var b2 := _lbl("  +1 granada extra por fase de construcción", 14, Color(0.75, 0.90, 0.60))
	b2.size = Vector2(PW - 40.0, 20); b2.position = Vector2(20, 174)
	b2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(b2)

	_add_sep(20.0, PH - 80.0)

	_act_btn = Button.new()
	_act_btn.add_theme_font_size_override("font_size", 15)
	_act_btn.size     = Vector2(200, 34)
	_act_btn.position = Vector2(PW * 0.5 - 100.0, PH - 72.0)
	_act_btn.pressed.connect(_try_activate)
	_panel.add_child(_act_btn)

	var hint := _lbl("[F] o [ESC] para cerrar", 12, Color(0.42, 0.52, 0.42))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(PW, 18); hint.position = Vector2(0, PH - 34.0)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hint)


func _try_activate() -> void:
	if _active or _biomasa < COST:
		return
	_biomasa -= COST
	_active   = true
	biomasa_spent.emit(COST)
	station_activated.emit()
	_refresh()


func _refresh() -> void:
	_bank_lbl.text = "CHATARRA DE MISIÓN:  %d  ◈" % _biomasa
	if _active:
		_status_lbl.text             = "ESTADO:  ACTIVO  ✓"
		_status_lbl.add_theme_color_override("font_color", Color(0.30, 1.0, 0.55))
		_act_btn.text                = "ACTIVO  ✓"
		_act_btn.disabled            = true
	else:
		_status_lbl.text             = "ESTADO:  INACTIVO"
		_status_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
		_act_btn.text                = "ACTIVAR  —  %d ◈" % COST
		_act_btn.disabled            = _biomasa < COST


func _add_sep(px_margin: float, y: float) -> void:
	var sep := ColorRect.new()
	sep.size         = Vector2(_panel.size.x - px_margin * 2.0, 1)
	sep.position     = Vector2(px_margin, y)
	sep.color        = Color(0.28, 0.50, 0.70, 0.45)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(sep)


func _lbl(text: String, sz: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", color)
	return l

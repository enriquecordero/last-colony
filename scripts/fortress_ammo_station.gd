extends CanvasLayer

signal biomasa_spent(amount: int)
signal grenade_added(count: int)
signal bomb_added(count: int)
signal sniper_ammo_added(count: int)
signal flame_fuel_added(count: int)
signal closed

const VIEW_W := 1280.0
const VIEW_H  := 720.0

var _panel:    Panel
var _bank_lbl: Label
var _biomasa:  int   = 0
var _rows:     Array = []   # [{row:Panel, btn:Button, cost:int}]


func _ready() -> void:
	layer   = 24
	visible = false
	_build()


func open(biomasa: int) -> void:
	_biomasa = biomasa
	visible  = true
	_refresh_all()


func close() -> void:
	visible = false
	closed.emit()


func refresh_biomasa(amount: int) -> void:
	_biomasa = amount
	if visible:
		_refresh_all()


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

	const PW := 460.0
	const PH := 400.0
	_panel          = Panel.new()
	_panel.size     = Vector2(PW, PH)
	_panel.position = Vector2((VIEW_W - PW) * 0.5, (VIEW_H - PH) * 0.5)
	add_child(_panel)

	var hdr := _lbl("◈  ARMERÍA  ◈", 27, Color(1.0, 0.85, 0.30))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.size = Vector2(PW, 42); hdr.position = Vector2(0, 12)
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hdr)

	var sub := _lbl("Reabastecimiento — usa chatarra de misión", 13, Color(0.65, 0.58, 0.42))
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

	var item_defs := [
		{"id": "sniper",  "label": "BALAS SNIPER",  "desc": "+3 balas de reserva",
			"cost": 5, "col": Color(0.80, 0.97, 1.00)},
		{"id": "fuel",    "label": "COMBUSTIBLE",   "desc": "+20 unidades de fuel",
			"cost": 4, "col": Color(1.00, 0.55, 0.15)},
		{"id": "grenade", "label": "GRANADA",        "desc": "+1 granada de mano",
			"cost": 5, "col": Color(0.35, 0.88, 0.45)},
		{"id": "bomb",    "label": "BOMBA TÁCTICA",  "desc": "+1 carga explosiva",
			"cost": 8, "col": Color(1.00, 0.42, 0.20)},
	]

	const IH  := 56.0
	const IGY := 8.0
	const SY  := 114.0
	const IX  := 24.0
	const IW  := PW - 48.0

	for i in item_defs.size():
		var def: Dictionary = item_defs[i]
		_add_item_row(def, IX, SY + float(i) * (IH + IGY), IW, IH)

	_add_sep(20.0, PH - 54.0)

	var hint := _lbl("[F] o [ESC] para cerrar", 12, Color(0.42, 0.52, 0.42))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(PW, 18); hint.position = Vector2(0, PH - 48.0)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hint)

	var close_btn := Button.new()
	close_btn.text = "CERRAR"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.size     = Vector2(120, 30)
	close_btn.position = Vector2(PW * 0.5 - 60.0, PH - 38.0)
	close_btn.pressed.connect(close)
	_panel.add_child(close_btn)


func _add_item_row(def: Dictionary, x: float, y: float, w: float, h: float) -> void:
	var col:     Color  = def["col"]
	var cost:    int    = def["cost"]
	var item_id: String = def["id"]

	var row := Panel.new()
	row.size     = Vector2(w, h)
	row.position = Vector2(x, y)
	_panel.add_child(row)

	var name_lbl := _lbl(def["label"], 16, col)
	name_lbl.size         = Vector2(w * 0.5, 22)
	name_lbl.position     = Vector2(8, 6)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_lbl)

	var desc_lbl := _lbl(def["desc"], 12, col.darkened(0.15))
	desc_lbl.size         = Vector2(w * 0.5, 18)
	desc_lbl.position     = Vector2(8, 28)
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(desc_lbl)

	var cost_lbl := _lbl("%d ◈" % cost, 15, Color(0.30, 0.95, 0.55))
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_lbl.size         = Vector2(90, 22)
	cost_lbl.position     = Vector2(w - 192.0, 16.0)
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cost_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "COMPRAR"
	buy_btn.add_theme_font_size_override("font_size", 13)
	buy_btn.size     = Vector2(90, 28)
	buy_btn.position = Vector2(w - 98.0, (h - 28.0) * 0.5)
	buy_btn.pressed.connect(func(): _try_purchase(item_id, cost, row))
	row.add_child(buy_btn)

	_rows.append({"row": row, "btn": buy_btn, "cost": cost})


func _try_purchase(item_id: String, cost: int, row: Panel) -> void:
	if _biomasa < cost:
		return
	_biomasa -= cost
	biomasa_spent.emit(cost)
	_refresh_all()

	match item_id:
		"sniper":  sniper_ammo_added.emit(3)
		"fuel":    flame_fuel_added.emit(20)
		"grenade": grenade_added.emit(1)
		"bomb":    bomb_added.emit(1)

	row.modulate = Color(1.5, 1.5, 1.2)
	var tw := row.create_tween()
	tw.tween_property(row, "modulate", Color.WHITE, 0.30)


func _refresh_all() -> void:
	_bank_lbl.text = "CHATARRA DE MISIÓN:  %d  ◈" % _biomasa
	for entry in _rows:
		var r: Panel  = entry["row"]
		var b: Button = entry["btn"]
		var c: int    = entry["cost"]
		b.disabled    = (_biomasa < c)
		r.modulate    = Color(1, 1, 1, 1.0) if _biomasa >= c else Color(1, 1, 1, 0.55)


func _add_sep(px_margin: float, y: float) -> void:
	var sep := ColorRect.new()
	sep.size         = Vector2(_panel.size.x - px_margin * 2.0, 1)
	sep.position     = Vector2(px_margin, y)
	sep.color        = Color(0.55, 0.42, 0.18, 0.50)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(sep)


func _lbl(text: String, sz: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", color)
	return l

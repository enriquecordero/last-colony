extends CanvasLayer

signal upgrade_bought
signal closed

const VIEW_W := 1280.0
const VIEW_H  := 720.0

var _panel:    Panel
var _bank_lbl: Label
var _cards:    Dictionary = {}   # key → {card, stars, btn}

func _ready() -> void:
	layer   = 25
	visible = false
	_build()

func open() -> void:
	visible = true
	_refresh_all()

func close() -> void:
	visible = false
	closed.emit()

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
	dim.color        = Color(0, 0, 0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	const PW := 790.0
	const PH := 540.0
	_panel          = Panel.new()
	_panel.size     = Vector2(PW, PH)
	_panel.position = Vector2((VIEW_W - PW) * 0.5, (VIEW_H - PH) * 0.5)
	add_child(_panel)

	var hdr := _lbl("◈  ÁRBOL DE HABILIDADES  ◈", 27, Color(0.30, 1.0, 0.42))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.size         = Vector2(PW, 42)
	hdr.position     = Vector2(0, 12)
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hdr)

	var sub := _lbl("Mejoras permanentes — persisten entre misiones", 13, Color(0.50, 0.65, 0.50))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size         = Vector2(PW, 20)
	sub.position     = Vector2(0, 54)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(sub)

	_bank_lbl = _lbl("", 18, Color(0.30, 0.95, 0.55))
	_bank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bank_lbl.size         = Vector2(PW, 26)
	_bank_lbl.position     = Vector2(0, 76)
	_bank_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_bank_lbl)

	_add_sep(24, 106)

	# Column headers
	var lh := _lbl("— COMBATE —", 13, Color(0.55, 0.68, 0.55))
	lh.size = Vector2(320, 20); lh.position = Vector2(28, 112)
	lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(lh)

	var rh := _lbl("— RESISTENCIA —", 13, Color(0.55, 0.68, 0.55))
	rh.size = Vector2(320, 20); rh.position = Vector2(440, 112)
	rh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(rh)

	# Cards — two columns
	var left_keys  := ["speed",   "fire",    "damage"]
	var right_keys := ["ammo",    "armor",   "rockets"]
	const CW := 320.0
	const CH := 82.0
	const GY := 10.0
	const SY := 136.0
	const LX := 28.0
	const RX := 442.0

	for i in 3:
		_add_card(left_keys[i],  LX, SY + i * (CH + GY), CW, CH)
		_add_card(right_keys[i], RX, SY + i * (CH + GY), CW, CH)
		if i < 2:
			_add_connector(LX + CW * 0.5 - 1, SY + i * (CH + GY) + CH, GY + 2)
			_add_connector(RX + CW * 0.5 - 1, SY + i * (CH + GY) + CH, GY + 2)

	_add_sep(24, PH - 56)

	var hint := _lbl("[F] o [ESC] para cerrar", 12, Color(0.42, 0.52, 0.42))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(PW, 18); hint.position = Vector2(0, PH - 50)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hint)

	var btn := Button.new()
	btn.text = "CERRAR"
	btn.add_theme_font_size_override("font_size", 15)
	btn.size     = Vector2(130, 32)
	btn.position = Vector2(PW * 0.5 - 65, PH - 42)
	btn.pressed.connect(close)
	_panel.add_child(btn)


func _add_card(key: String, x: float, y: float, w: float, h: float) -> void:
	var info: Dictionary = StageManager.META_TREE.get(key, {})
	var col: Color       = info.get("color", Color.WHITE)

	var card         := Panel.new()
	card.size         = Vector2(w, h)
	card.position     = Vector2(x, y)
	_panel.add_child(card)

	var name_lbl := _lbl(info.get("label", key), 18, col)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.size         = Vector2(w, 26)
	name_lbl.position     = Vector2(0, 6)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)   # idx 0

	var stars_lbl := _lbl("", 14, col.lightened(0.25))
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_lbl.size         = Vector2(w, 20)
	stars_lbl.position     = Vector2(0, 32)
	stars_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stars_lbl)  # idx 1

	var buy_btn := Button.new()
	buy_btn.add_theme_font_size_override("font_size", 13)
	buy_btn.size     = Vector2(w - 16, 24)
	buy_btn.position = Vector2(8, 54)
	buy_btn.pressed.connect(func(): _try_buy(key))
	card.add_child(buy_btn)    # idx 2

	_cards[key] = {"card": card, "stars": stars_lbl, "btn": buy_btn}


func _add_sep(px_margin: float, y: float) -> void:
	var sep := ColorRect.new()
	sep.size         = Vector2(_panel.size.x - px_margin * 2.0, 1)
	sep.position     = Vector2(px_margin, y)
	sep.color        = Color(0.28, 0.42, 0.28, 0.50)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(sep)


func _add_connector(x: float, y: float, h: float) -> void:
	var c := ColorRect.new()
	c.size         = Vector2(2, h)
	c.position     = Vector2(x, y)
	c.color        = Color(0.28, 0.42, 0.28, 0.45)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(c)


func _try_buy(key: String) -> void:
	if StageManager.buy_meta(key):
		upgrade_bought.emit()
		_refresh_all()


func _refresh_all() -> void:
	_bank_lbl.text = "CHATARRA ACUMULADA:  %d  ◈" % StageManager.chatarra_banked
	for key in _cards:
		_refresh_card(key)


func _refresh_card(key: String) -> void:
	var entry: Dictionary = _cards.get(key, {})
	if entry.is_empty():
		return
	var card:  Panel  = entry["card"]
	var stars: Label  = entry["stars"]
	var btn:   Button = entry["btn"]

	var lv    := StageManager.get_meta_level(key)
	var info: Dictionary = StageManager.META_TREE.get(key, {})
	var maxlv := int(info.get("max", 3))
	var col:   Color = info.get("color", Color.WHITE)
	var cost   := StageManager.get_meta_cost(key)

	var star_str := ""
	for i in maxlv:
		star_str += ("★" if i < lv else "☆") + " "
	stars.text = star_str.strip_edges()
	stars.add_theme_color_override("font_color", col.lightened(0.2))

	if lv >= maxlv:
		btn.text      = "MÁXIMO  ✓"
		btn.disabled  = true
		card.modulate = Color(1, 1, 1, 0.60)
	elif cost >= 0 and StageManager.chatarra_banked >= cost:
		btn.text      = "MEJORAR  —  %d ◈" % cost
		btn.disabled  = false
		card.modulate = Color(1, 1, 1, 1.0)
	else:
		var short := cost - StageManager.chatarra_banked
		btn.text      = "%d ◈  (faltan %d)" % [cost, short]
		btn.disabled  = true
		card.modulate = Color(1, 1, 1, 0.50)


func _lbl(text: String, sz: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", color)
	return l

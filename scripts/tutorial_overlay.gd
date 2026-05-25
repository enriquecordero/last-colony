extends Control

signal finished

const _STEPS: Array = [
	{
		"title": "BIENVENIDO AL CAMPO DE PRUEBAS",
		"body":  "Probá libremente las mecánicas. No hay derrota — la base es invulnerable.\n\nSPACE: siguiente   ESC: cerrar overlay",
	},
	{
		"title": "MOVIMIENTO + DISPARO",
		"body":  "WASD para moverte.\nClick izquierdo para disparar (mantenelo para rifle).\nR para recargar.\nSPACE / ui_arrows también funcionan.",
	},
	{
		"title": "DASH",
		"body":  "Tecla SPACE = dash corto en la dirección de movimiento.\nSirve para esquivar masas y atravesar grupos rápido.",
	},
	{
		"title": "GRANADA",
		"body":  "Click DERECHO en el mapa = lanzar granada al instante.\nExplota en radio amplio — guardala para clústeres densos.",
	},
	{
		"title": "ESTRATAGEMAS (Helldivers style)",
		"body":  "TAB entra modo estratagema. Tipeás flechas:\n\n↑↑↓↓     SUPPLY (munición + granadas)\n→↓←→     SENTRY (torreta automática 60s)\n←↑→↓     AIRSTRIKE (5 explosiones)\n←↑→↓↑    REFUERZOS (3 grunts)\n\nCódigo válido → click marca el drop. ESC cancela.",
	},
	{
		"title": "ÓRDENES AL ESCUADRÓN",
		"body":  "V + click  = todos los NPCs combatientes van al punto que marcaste.\nH         = el médico viene a vos directamente.\n\nÚtil para defender una brecha o juntar tropa en el frente correcto.",
	},
	{
		"title": "LÁSER ORBITAL",
		"body":  "Tecla L activa modo apuntado. Click marca el spot — 2.4s después cae un rayo masivo (600 dmg en radio 130).\nEmpezás con 2 cargas, +1 por wave (tope 4).",
	},
	{
		"title": "FASE DE CONSTRUCCIÓN",
		"body":  "Entre waves tenés ~14s para construir:\nB=muro  T=torreta  N=muro+  M=mina  C=barricada  X=mortero\n\nClick derecho durante esa fase = reparar muro cercano (-2 chatarra).",
	},
	{
		"title": "ROLES DE NPCs",
		"body":  "MÉDICO: te revive si caés (vital).\nINGENIERO: repara muros automáticamente.\nSNIPER: prioriza enemigos elite (tanque, blindado).\nDEMOLICIONES: lanza granadas a clústeres.\nASALTO + GRUNTS: DPS general.",
	},
	{
		"title": "¡PROBÁ TODO!",
		"body":  "Ahora andá y rompé cosas.\n\nDel toque ESC para cerrar este overlay y jugar tranqui.\nPodés volver al stage select cuando quieras pausando con ESC dos veces.",
	},
]

var _idx: int = 0
var _panel: Panel = null
var _title_lbl: Label = null
var _body_lbl:  Label = null
var _hint_lbl:  Label = null


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right  = 1.0
	anchor_bottom = 1.0
	z_index       = 80
	_build()
	_show_step()


func _build() -> void:
	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.02, 0.04, 0.08, 0.55)
	add_child(bg)

	_panel = Panel.new()
	_panel.size = Vector2(620, 320)
	_panel.position = Vector2(330, 200)
	add_child(_panel)

	_title_lbl = Label.new()
	_title_lbl.size = Vector2(580, 36)
	_title_lbl.position = Vector2(20, 18)
	_title_lbl.add_theme_font_size_override("font_size", 22)
	_title_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	_panel.add_child(_title_lbl)

	_body_lbl = Label.new()
	_body_lbl.size = Vector2(580, 220)
	_body_lbl.position = Vector2(20, 60)
	_body_lbl.add_theme_font_size_override("font_size", 15)
	_body_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.85))
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_body_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.size = Vector2(580, 24)
	_hint_lbl.position = Vector2(20, 290)
	_hint_lbl.add_theme_font_size_override("font_size", 12)
	_hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.65))
	_panel.add_child(_hint_lbl)


func _show_step() -> void:
	var s: Dictionary = _STEPS[_idx]
	_title_lbl.text = s["title"]
	_body_lbl.text  = s["body"]
	_hint_lbl.text  = "Paso %d / %d   —   SPACE: siguiente   ESC: cerrar" % [_idx + 1, _STEPS.size()]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_SPACE, KEY_KP_ENTER, KEY_ENTER:
			_advance()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			finished.emit()
			get_viewport().set_input_as_handled()


func _advance() -> void:
	_idx += 1
	if _idx >= _STEPS.size():
		finished.emit()
		return
	_show_step()

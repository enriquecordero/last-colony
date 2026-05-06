extends Area2D

signal collected(amount: int)

var amount: int = 1

func _ready() -> void:
	collision_layer = 16
	collision_mask  = 1
	monitoring      = true
	monitorable     = false
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(18.0).timeout.connect(queue_free)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7, Color(0.15, 0.82, 0.38))
	draw_arc(Vector2.ZERO, 7, 0, TAU, 18, Color(0.4, 1.0, 0.6), 1.8)
	draw_circle(Vector2.ZERO, 3, Color(0.6, 1.0, 0.7))

func _on_body_entered(body: Node) -> void:
	if body.has_method("collect_biomasa"):
		body.collect_biomasa(amount)
		collected.emit(amount)
		queue_free()

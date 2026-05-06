extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed:     float   = 245.0
var damage:    int     = 10
var lifetime:  float   = 2.4

func _ready() -> void:
	collision_layer = 32
	collision_mask  = 9
	monitoring      = true
	monitorable     = false
	var shape        := CircleShape2D.new()
	shape.radius      = 5.0
	var col           := CollisionShape2D.new()
	col.shape          = shape
	add_child(col)
	body_entered.connect(_on_hit)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	queue_redraw()

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_hit(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.5, Color(0.80, 0.20, 0.90))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0,  0.65, 1.0))

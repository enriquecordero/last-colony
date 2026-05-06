extends Area2D

const BASE_SPEED = 650.0
const HitSpark   = preload("res://scripts/hit_spark.gd")

var direction: Vector2 = Vector2.RIGHT
var lifetime:  float   = 2.5
var damage:    int     = 10
var bcolor:    Color   = Color(1.0, 0.95, 0.1)
var bradius:   float   = 8.0

func _ready() -> void:
	collision_layer = 4
	collision_mask  = 2
	monitoring      = true
	monitorable     = false
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, bradius, bcolor)

func _physics_process(delta: float) -> void:
	position += direction * BASE_SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		var spark        := HitSpark.new()
		spark.global_position = global_position
		spark._color     = bcolor
		get_parent().add_child(spark)
	queue_free()

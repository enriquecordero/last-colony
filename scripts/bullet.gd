extends Area2D

const BASE_SPEED = 650.0
const HitBlood   = preload("res://scripts/hit_blood.gd")
const HitSpark   = preload("res://scripts/hit_spark.gd")

var direction: Vector2 = Vector2.RIGHT
var lifetime:  float   = 2.5
var damage:    int     = 10
var bcolor:    Color   = Color(1.0, 0.95, 0.1)
var bradius:   float   = 8.0
var is_flame:  bool    = false   # lanzallamas keeps circular fireball


func _ready() -> void:
	collision_layer = 4
	collision_mask  = 2
	monitoring      = true
	monitorable     = false
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	queue_redraw()


func _draw() -> void:
	if is_flame:
		# Lanzallamas: soft glowing fireball
		draw_circle(Vector2.ZERO, bradius, bcolor)
		draw_circle(Vector2.ZERO, bradius * 0.55, Color(1.0, 1.0, 0.8, 0.7))
	else:
		# Elongated bullet capsule aligned with travel direction
		var len    := bradius * 2.2
		var width  := bradius * 0.55
		var tip    :=  direction * len
		var tail   := -direction * len * 0.45
		# Core bright streak
		draw_line(tail, tip, bcolor, width, true)
		# Bright leading tip highlight
		draw_circle(tip, width * 0.6, Color(1.0, 1.0, 0.95, 0.9))
		# Faint glow halo
		draw_line(tail, tip, Color(bcolor.r, bcolor.g, bcolor.b, 0.25), width * 2.0, true)


func _physics_process(delta: float) -> void:
	position += direction * BASE_SPEED * delta


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		# collision_mask=2 means only enemies are hit — always show blood
		if not is_flame:
			var blood              := HitBlood.new()
			blood.global_position  = global_position
			blood.hit_direction    = direction
			get_parent().add_child(blood)
		else:
			var spark              := HitSpark.new()
			spark.global_position  = global_position
			spark._color           = bcolor
			get_parent().add_child(spark)
	queue_free()

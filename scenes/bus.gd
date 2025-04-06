extends Area2D

# Bus properties
@export var speed = 700  # Pixels per second

func _process(delta):
	# Simple movement - just move left
	position.x -= speed * delta

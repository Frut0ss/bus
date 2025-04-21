extends Node2D

@export var scroll_speed = 300.0
var is_moving = true

func _process(delta):
	if is_moving:
		# The ParallaxBackground will handle the different speeds for each layer
		# based on their motion_scale values
		$ParallaxBackground.scroll_offset.x += scroll_speed * delta

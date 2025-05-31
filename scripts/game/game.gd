extends Node2D

func _ready():
	# Wait a small moment to ensure everything is initialized
	await get_tree().create_timer(0.1).timeout
	
	# Change to the map scene
	SceneTransitionManager.change_scene("map")

func _process(_delta):
	if Input.is_action_just_pressed("click"):  # Use just_pressed instead of is_action_pressed
		SceneTransitionManager.change_scene("bus_stop")
	

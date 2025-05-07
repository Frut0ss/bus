extends Node

@onready var transition_overlay: ColorRect = $TransitionOverlay

# Paths to scenes for easy reference
var scenes = {
	"map": "res://scenes/game/map_scene.tscn",
	"bus_stop": "res://scenes/stops/bus_stop.tscn",
	"interior_bus": "res://scenes/game/interior_scene.tscn",
}


# Track current scene
var current_scene = null
var is_transitioning = false

# Called when the node enters the scene tree
func _ready():
	# Get the current scene when the game starts
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)


# Basic scene change without animation
func change_scene(scene_name):
	# Make sure the scene exists in our dictionary
	if not scenes.has(scene_name):
		print("Scene not found: ", scene_name)
		return
	
	# Get the scene resource
	var scene_resource = load(scenes[scene_name])
	
	# Instance the new scene
	var new_scene = scene_resource.instantiate()
	
	# Add the new scene to the tree
	get_tree().get_root().add_child(new_scene)
	
	if current_scene != null:
		current_scene.queue_free()
	
	# Update current scene reference
	current_scene = new_scene


# NEED FIXING
#func fade_to_scene(scene_name, duration = 0.5):
	#if is_transitioning:
		#return
	#
	#is_transitioning = true
	#
	## Fade out
	##transition_overlay.color.a = 0
	#transition_overlay.visible = true
	#
	#var tween = create_tween()
	#tween.tween_property(transition_overlay, "color:a", 1.0, duration)
	#await tween.finished
	#
	## Change scene
	#change_scene(scene_name)
	#
	## Fade in
	#tween = create_tween()
	#tween.tween_property(transition_overlay, "color:a", 0.0, duration)
	#await tween.finished
	#
	#transition_overlay.visible = false
	#is_transitioning = false

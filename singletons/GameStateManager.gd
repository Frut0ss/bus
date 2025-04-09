# game_state_manager.gd
extends Node

enum GameState {MAP_VIEW, BUS_STOP, INTERIOR_BUS}
var current_state = GameState.MAP_VIEW

# Add a property to track selected stop on map
var selected_map_stop_id = ""

func _process(delta):
	match current_state:
		GameState.MAP_VIEW:
			if Input.is_action_just_pressed("click"):
				# In a real implementation, you would check if a bus stop
				# was clicked and set selected_map_stop_id accordingly
				selected_map_stop_id = "test_stop" # For testing
				change_to_state(GameState.BUS_STOP)
		GameState.BUS_STOP:
			if Input.is_action_just_pressed("click"):
				change_to_state(GameState.INTERIOR_BUS)
		GameState.INTERIOR_BUS:
			if Input.is_action_just_pressed("click"):
				change_to_state(GameState.MAP_VIEW)

func change_to_state(new_state):
	current_state = new_state
	
	match new_state:
		GameState.MAP_VIEW:
			# Clear current bus/bus stop selection when returning to map
			TransitSystem.current_bus_line = null
			SceneTransitionManager.change_scene("map")
		GameState.BUS_STOP:
			# Set the current bus stop in TransitSystem
			if selected_map_stop_id != "":
				TransitSystem.set_current_bus_stop(selected_map_stop_id)
			SceneTransitionManager.change_scene("bus_stop")
		GameState.INTERIOR_BUS:
			# The current bus should already be set when boarding
			SceneTransitionManager.change_scene("interior_bus")

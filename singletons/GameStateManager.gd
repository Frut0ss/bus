# game_state_manager.gd
extends Node

# Define game states as an enum for clarity and structure
enum GameState { MAP_VIEW, BUS_STOP, INTERIOR_BUS }

# The current game state, initialized to MAP_VIEW (when the player is on the map)
var current_state = GameState.MAP_VIEW

# ID of the selected bus stop (initially empty)
var selected_map_stop_id = ""

# Tracks if the player has boarded the bus (starts as false)
var has_boarded_bus = false

# The current index of the bus stop the player is at (starts at 0)
var current_stop_index = 0

# The process function is called every frame
func _process(delta):
	# Use a match statement to handle different game states
	match current_state:
		# If the player is in the MAP_VIEW (map screen)
		GameState.MAP_VIEW:
			if Input.is_action_just_pressed("click"):
				# For testing: Simulate the selection of a bus stop
				selected_map_stop_id = "test_stop"
				# Change the game state to BUS_STOP, where the player selects a bus stop
				change_to_state(GameState.BUS_STOP)

		# If the player is at the BUS_STOP screen (choosing a bus stop)
		GameState.BUS_STOP:
			if Input.is_action_just_pressed("click"):
				# Move to the INTERIOR_BUS state when the player clicks (simulating boarding the bus)
				change_to_state(GameState.INTERIOR_BUS)

		# If the player is inside the bus (INTERIOR_BUS state)
		GameState.INTERIOR_BUS:
			if Input.is_action_just_pressed("click"):
				# If the player clicks, go back to the map screen
				change_to_state(GameState.MAP_VIEW)

# Function to change the game state and handle scene transitions
func change_to_state(new_state):
	# Update the current state to the new state
	current_state = new_state
	
	# Use a match statement to handle what happens when the game state changes
	match new_state:
		# When transitioning to the MAP_VIEW state
		GameState.MAP_VIEW:
			# Reset the current bus line to null when returning to the map view
			TransitSystem.current_bus_line = null
			# Transition to the "map" scene (show the map)
			SceneTransitionManager.change_scene("map")

		# When transitioning to the BUS_STOP state
		GameState.BUS_STOP:
			if selected_map_stop_id != "":
				# If a stop has been selected, set the current bus stop in the system
				TransitSystem.set_current_bus_stop(selected_map_stop_id)
			# Transition to the "bus_stop" scene (where the player selects a bus stop)
			SceneTransitionManager.change_scene("bus_stop")

		# When transitioning to the INTERIOR_BUS state
		GameState.INTERIOR_BUS:
			# Mark that the player has boarded the bus
			has_boarded_bus = true
			# Transition to the "interior_bus" scene (inside the bus)
			SceneTransitionManager.change_scene("interior_bus")

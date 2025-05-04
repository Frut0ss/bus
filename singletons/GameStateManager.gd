extends Node

# Define game states as an enum for clarity and structure
enum GameState { MAP_VIEW, BUS_STOP, INTERIOR_BUS, GAME_WON }

# The current game state, initialized to MAP_VIEW (when the player is on the map)
var current_state = GameState.MAP_VIEW

# ID of the selected bus stop (initially empty)
var selected_map_stop_id = ""

# Tracks if the player has boarded the bus (starts as false)
var has_boarded_bus = false


# Preload the win scene here
var win_scene = preload("res://scenes/win.tscn")

# The process function is called every frame
func _process(delta):
	# Use a match statement to handle different game states
	match current_state:
		# If the player is in the MAP_VIEW (map screen)
		GameState.MAP_VIEW:
			if check_destination():
				pass
			else:
				if Input.is_action_just_pressed("click"):
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

		# Handle GAME_WON state (after the game is won)
		GameState.GAME_WON:
			# When the game is won, show the win screen
			show_win_screen()

# Function to change the game state and handle scene transitions
func change_to_state(new_state):
	# Update the current state to the new state
	current_state = new_state
	
	# Use a match statement to handle what happens when the game state changes
	match new_state:
		# When transitioning to the MAP_VIEW state
		GameState.MAP_VIEW:
			# Check if we've reached the destination
			if check_destination():
				# If we've reached the destination, the check_destination function
				# will change the state to GAME_WON, so we don't need to do anything else
				pass
			else:
				# Reset the current bus line to null when returning to the map view
				TransitSystem.current_bus_line = null
				# Transition to the "map" scene (show the map)
				SceneTransitionManager.change_scene("map")
			
		# When transitioning to the BUS_STOP state
		GameState.BUS_STOP:
			# Transition to the "bus_stop" scene (where the player selects a bus stop)
			SceneTransitionManager.change_scene("bus_stop")
			
		# When transitioning to the INTERIOR_BUS state
		GameState.INTERIOR_BUS:
			# Mark that the player has boarded the bus
			has_boarded_bus = true
			# Transition to the "interior_bus" scene (inside the bus)
			SceneTransitionManager.change_scene("interior_bus")
			
		# When the game is won, transition to the win screen
		GameState.GAME_WON:
			# Transition to the "win" scene
			SceneTransitionManager.change_scene("win")

# Function to handle showing the win screen
func show_win_screen():
	# Ensure the win scene is loaded and instantiated when the game is won
	var win_screen = win_scene.instantiate()

	# Get the current scene and add the win screen to it
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(win_screen)
	else:
		get_tree().root.add_child(win_screen)

	# Optionally, set the text of the win message
	var label = win_screen.get_node("Label")  # Ensure you have a Label node
	if label:
		label.text = "You Won!"  # Set the win message

func check_destination():
	# Get the current stop index from TransitSystem
	var current_index = TransitSystem.current_stop_index
	var destination_index = TransitSystem.destination_index
	
	# Check if we've reached the destination
	if current_index == destination_index:
		print("Destination reached!")
		change_to_state(GameState.GAME_WON)
		return true
	
	return false

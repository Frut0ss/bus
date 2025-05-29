extends Node2D

@onready var bus_spawn_timer: Timer = $BusSpawnTimer
@onready var bus_spawn_position: Marker2D = $BusSpawnPosition
@onready var bus_despawn_position: Marker2D = $BusDespawnPosition
@export var bus_scene = preload("res://scenes/bus/bus.tscn")
@onready var character_player: CharacterBody2D = $CharacterPlayer
@onready var direction_label: Label = $DirectionLabel
@onready var direction_button: Button = $DirectionButton


# UI elements (you'll need to add these to your scene)
@onready var stop_name_label = $StopNameLabel
@onready var neighborhood_label = $NeighborhoodLabel
@onready var bus_stop_audio: AudioStreamPlayer2D = $BusStopAudio

var active_buses = []
var current_bus_stop = null

# Update the _ready function in bus_stop.gd

# Modify the _ready function in bus_stop.gd

func _ready():
	print("Bus stop scene initializing...")
	
	# Get current bus stop from the transit system
	if TransitSystem.current_bus_stop:
		current_bus_stop = TransitSystem.current_bus_stop
		print("Current bus stop: " + current_bus_stop.display_name)
	else:
		print("ERROR: No current bus stop set in TransitSystem!")
	
	# Connect to direction changed signal
	if not TransitSystem.is_connected("direction_changed", Callable(self, "_on_direction_changed")):
		TransitSystem.connect("direction_changed", Callable(self, "_on_direction_changed"))
	
	# Connect direction button
	if direction_button:
		direction_button.connect("pressed", Callable(self, "_on_direction_button_pressed"))
	else:
		print("ERROR: No direction button found!")
	
	# Check if we have an active bus line - if not, set one
	if not TransitSystem.active_bus_line:
		print("No active bus line on bus stop initialization - setting one...")
		
		if current_bus_stop and not current_bus_stop.connected_lines.is_empty():
			var bus_line = current_bus_stop.connected_lines[0]
			print("Setting initial active bus line to: " + bus_line.display_name)
			TransitSystem.set_active_bus_line(bus_line)
		else:
			print("ERROR: Cannot set initial active bus line - no connected lines at this stop!")
	else:
		print("Active bus line already set: " + TransitSystem.active_bus_line.display_name)
	
	# Update display with the current bus stop info
	update_bus_stop_display()
	
	# Start the timer
	bus_spawn_timer.start()
	
func _process(_delta):
	# Check if any buses have reached the despawn position
	for bus in active_buses:
		if bus != null:
			# Check if bus passed without stopping
			if bus.position.x <= bus_despawn_position.position.x:
				remove_bus(bus)
			
			# Handle boarding for stopped buses
			if bus.can_player_board() and bus.at_bus_stop and Input.is_action_pressed("Embark"):
				board_player(bus)
				break

func update_bus_stop_display():
	if current_bus_stop:
		# Update UI elements with bus stop information
		if stop_name_label:
			stop_name_label.text = current_bus_stop.display_name
		
		if neighborhood_label:
			neighborhood_label.text = current_bus_stop.neighborhood.display_name
		
		update_direction_display()
		# You could also update the background or other visual elements
		# based on the neighborhood or other properties

# Modify the update_direction_display function in bus_stop.gd

func update_direction_display():
	
	# Check what directions are available
	var available_directions = check_available_directions()
	
	# Update button state based on available directions
	if direction_button:
		var current_direction_valid = true
		
		if TransitSystem.travel_direction == 1 and not available_directions.forward:
			TransitSystem.travel_direction = -1
		elif TransitSystem.travel_direction == -1 and not available_directions.backward:
			TransitSystem.travel_direction = 1
		
		# Disable button if only one direction is possible
		if available_directions.forward and available_directions.backward:
			direction_button.disabled = false
			direction_button.text = "Change Direction"
		else:
			direction_button.disabled = true
			if available_directions.forward:
				direction_button.text = "Forward Only"
			elif available_directions.backward:
				direction_button.text = "Backward Only"
			else:
				direction_button.text = "No Travel"
	
	if not TransitSystem.active_bus_line:
		
		# Set a fallback active line if possible
		if current_bus_stop and not current_bus_stop.connected_lines.is_empty():
			var bus_line = current_bus_stop.connected_lines[0]
			TransitSystem.set_active_bus_line(bus_line)
		else:
			direction_label.text = "Towards: End of Line"
			return
	
	# Now try to get the terminus
	var terminus = TransitSystem.get_direction_terminus()
	var direction_name = "Forward" if TransitSystem.travel_direction == 1 else "Backward"
	direction_label.text = direction_name + " - Towards: " + terminus
	print("Setting direction label to: " + direction_label.text)

func _on_bus_stop_changed(new_stop):
	current_bus_stop = new_stop
	update_bus_stop_display()
	
	# You might want to clear existing buses when changing stops
	for bus in active_buses:
		remove_bus(bus)
	
	# Reset the bus spawn timer
	bus_spawn_timer.start()
			
func board_player(bus):
	var player = character_player
	if player:
		player.start_boarding()
		bus.board_player(player)
		
		# Store the bus line in TransitSystem
		TransitSystem.current_bus_line = bus.bus_line
		
		# Set the active bus line and update the stops
		TransitSystem.set_active_bus_line(bus.bus_line)
		
		if bus.bus_line:
			print("Player boarded " + bus.bus_line.display_name + " going " + 
				  ("forward" if TransitSystem.travel_direction == 1 else "backward"))
		
		# Find the current stop's index in this bus line
		var found_stop = false
		for i in range(TransitSystem.active_route_stops.size()):
			if TransitSystem.active_route_stops[i].display_name == current_bus_stop.display_name:
				TransitSystem.current_stop_index = i
				found_stop = true
				print("Found current stop '" + current_bus_stop.display_name + "' at index " + str(i))
				break
		
		if not found_stop:
			print("WARNING: Current stop not found in bus line, using default")
			# If going forward, start at beginning; if backward, start at end
			if TransitSystem.travel_direction == 1:
				TransitSystem.current_stop_index = 0
			else:
				TransitSystem.current_stop_index = TransitSystem.active_route_stops.size() - 1
		
		# Now advance to the next stop in the chosen direction
		print("Advancing to next stop from index: " + str(TransitSystem.current_stop_index) + 
			  " in direction: " + str(TransitSystem.travel_direction))
		
		TransitSystem.advance_to_next_stop()
		print("Now at stop index: " + str(TransitSystem.current_stop_index))
		
		# Change state to interior bus
		GameStateManager.change_to_state(GameStateManager.GameState.INTERIOR_BUS)

func _on_bus_spawn_timer_timeout():
	# Spawn a new bus
	spawn_bus()

func spawn_bus():
	# If we have bus lines connected to this stop, spawn a random one
	if current_bus_stop and not current_bus_stop.connected_lines.is_empty():
		# Get a random bus line from the available ones
		var random_index = randi() % current_bus_stop.connected_lines.size()
		var bus_line = current_bus_stop.connected_lines[random_index]
		
		print("Selected random bus line: " + bus_line.display_name)
		
		# Create the bus
		var new_bus = bus_scene.instantiate()
		
		# Set bus position
		new_bus.position = bus_spawn_position.position
		
		# Pass the bus stop position to the bus
		new_bus.set_bus_stop_position($BusStopPosition.position.x)
		
		# Set the bus color to match the line
		new_bus.modulate = bus_line.color
		
		# Store the bus line on the bus for reference
		new_bus.bus_line = bus_line
		
		# Add the bus to the scene
		add_child(new_bus)
		#play_bus_arrival()
		var direction_text = "Towards: " + TransitSystem.get_direction_terminus(bus_line)
		new_bus.set_direction_text(direction_text)
		
		# Display the bus line name
		new_bus.display_bus_line(bus_line.display_name)
		
		# Add to our active buses array for tracking
		active_buses.append(new_bus)
		
		print("Spawned bus for line: " + bus_line.display_name)
	else:
		print("No bus lines available at this stop!")
		
func remove_bus(bus):
	# Remove from active buses array
	if bus in active_buses:
		active_buses.erase(bus)
	
	# Queue for deletion
	bus.queue_free()

func _on_direction_button_pressed():
	print("Direction button pressed")
	
	# Check the active_bus_line before toggling
	if TransitSystem.active_bus_line:
		print("BUS STOP: Active bus line before toggle: " + TransitSystem.active_bus_line.display_name)
		print("BUS STOP: Has " + str(TransitSystem.active_route_stops.size()) + " stops")
	else:
		print("BUS STOP: No active bus line before toggle! Attempting to set one...")
		
		# If there's no active bus line, try to set one from the current stop
		if current_bus_stop and not current_bus_stop.connected_lines.is_empty():
			var bus_line = current_bus_stop.connected_lines[0]
			print("BUS STOP: Setting active bus line to: " + bus_line.display_name)
			TransitSystem.set_active_bus_line(bus_line)
		else:
			print("BUS STOP: Cannot set active bus line - no connected lines at this stop")
			
		# Toggle direction in the TransitSystem
	TransitSystem.toggle_direction()
	
	# Check the active_bus_line after toggling
	if TransitSystem.active_bus_line:
		print("BUS STOP: Active bus line after toggle: " + TransitSystem.active_bus_line.display_name)
	else:
		print("BUS STOP: No active bus line after toggle!")

func _on_direction_changed(_new_direction):
	print("Direction changed to: " + ("Forward" if _new_direction == 1 else "Backward"))
	
	# Check active_bus_line
	if TransitSystem.active_bus_line:
		print("DIRECTION CHANGED: Active bus line exists: " + TransitSystem.active_bus_line.display_name)
	else:
		print("DIRECTION CHANGED: No active bus line!")
	
	# Update the direction display
	update_direction_display()
	
	# Debug the terminus after direction change
	var terminus = TransitSystem.get_direction_terminus()
	print("DIRECTION CHANGED: New terminus: " + terminus)
	
	# Update buses
	for bus in active_buses:
		if bus.has_method("set_direction_text"):
			var direction_text = "Towards: " + terminus
			print("DIRECTION CHANGED: Setting bus text to: " + direction_text)
			bus.set_direction_text(direction_text)
		else:
			print("DIRECTION CHANGED: Bus doesn't have set_direction_text method")

func check_available_directions():
	if not current_bus_stop or current_bus_stop.connected_lines.is_empty():
		return {"forward": false, "backward": false, "reason": "No bus lines available"}
	
	var can_go_forward = false
	var can_go_backward = false
	var restriction_reason = ""
	
	# Check each connected bus line to see what directions are possible
	for bus_line in current_bus_stop.connected_lines:
		if not bus_line.stops or bus_line.stops.size() == 0:
			continue
			
		# Find current stop's position in this line
		var current_stop_index = -1
		for i in range(bus_line.stops.size()):
			if bus_line.stops[i].display_name == current_bus_stop.display_name:
				current_stop_index = i
				break
		
		if current_stop_index == -1:
			continue  # Current stop not found in this line
		
		# Check if we can go forward (toward end of line)
		if current_stop_index < bus_line.stops.size() - 1:
			can_go_forward = true
		
		# Check if we can go backward (toward beginning of line)
		if current_stop_index > 0:
			can_go_backward = true
	
	# Determine restriction reason
	if not can_go_forward and not can_go_backward:
		restriction_reason = "No travel possible from this stop"
	elif not can_go_forward:
		restriction_reason = "At end of all lines - can only go backward"
	elif not can_go_backward:
		restriction_reason = "At beginning of all lines - can only go forward"
	else:
		restriction_reason = "Both directions available"
	
	print("Direction check: Forward=" + str(can_go_forward) + ", Backward=" + str(can_go_backward) + " (" + restriction_reason + ")")
	
	return {
		"forward": can_go_forward,
		"backward": can_go_backward,
		"reason": restriction_reason
	}



func play_bus_arrival():
	bus_stop_audio.stream = load("res://assets/audio/bus.ogg")
	bus_stop_audio.play()

func play_stop_announcement():
	bus_stop_audio.stream = load("res://assets/audio/bus_stop_announcement.ogg")
	bus_stop_audio.play()

func play_boarding_beep():
	bus_stop_audio.stream = load("res://assets/audio/beepbeeppediastrian.ogg")
	bus_stop_audio.play()

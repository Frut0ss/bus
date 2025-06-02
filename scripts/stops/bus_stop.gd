extends Node2D

@onready var bus_spawn_timer: Timer = $BusSpawnTimer
@onready var bus_spawn_position: Marker2D = $BusSpawnPosition
@onready var bus_despawn_position: Marker2D = $BusDespawnPosition
@export var bus_scene = preload("res://scenes/bus/bus.tscn")
@onready var character_player: CharacterBody2D = $CharacterPlayer
@onready var direction_label: Label = $DirectionLabel
@onready var direction_button: Button = $DirectionButton

# UI elements
@onready var stop_name_label: Label = $BusStop/StopNameLabel
@onready var neighborhood_label: Label = $BusStop/NeighborhoodLabel
@onready var bus_stop_audio: AudioStreamPlayer2D = $BusStopAudio

# Bus signaling system
@onready var next_bus_panel: Panel = $NextBusPanel
@onready var countdown_label: Label = $NextBusPanel/CountdownLabel
@onready var bus_line_label: Label = $NextBusPanel/BusLineLabel
@onready var next_bus_label: Label = $NextBusPanel/NextBusLabel

var player_has_signaled = false
var next_bus_line = null
var preview_timer: Timer
var countdown_timer: Timer

var active_buses = []
var current_bus_stop = null

func _ready():
	# Get current bus stop from the transit system
	if TransitSystem.current_bus_stop:
		current_bus_stop = TransitSystem.current_bus_stop
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
		if current_bus_stop and not current_bus_stop.connected_lines.is_empty():
			var bus_line = current_bus_stop.connected_lines[0]
			TransitSystem.set_active_bus_line(bus_line)
		else:
			print("ERROR: Cannot set initial active bus line - no connected lines at this stop!")
	
	# Update display with the current bus stop info
	update_bus_stop_display()
	
	next_bus_panel.visible = false
	# Start the timer
	bus_spawn_timer.start()
	
func _process(_delta):
	# Check for signal input (E key) - only during preview
	if Input.is_action_just_pressed("Embark") and next_bus_line and not player_has_signaled and next_bus_panel.visible:
		signal_bus()
	
	# Check if any buses have reached the despawn position
	for bus in active_buses:
		if bus != null:
			if bus.position.x <= bus_despawn_position.position.x:
				remove_bus(bus)
			
			# Handle boarding for stopped buses
			if bus.can_player_board_this_bus() and bus.at_bus_stop:
				board_player(bus)
				break

func show_bus_preview():
	if next_bus_panel and next_bus_line:
		next_bus_panel.visible = true
		
		# Update labels
		if next_bus_label:
			next_bus_label.text = "Next Bus: Press E to Signal"
		if bus_line_label:
			bus_line_label.text = next_bus_line.display_name
			bus_line_label.modulate = next_bus_line.color
		
		update_direction_display(next_bus_line)

func signal_bus():
	player_has_signaled = true
	if next_bus_label:
		next_bus_label.text = "Bus Signaled!"
		next_bus_label.modulate = Color.GREEN

func update_bus_stop_display():
	if current_bus_stop:
		# Update UI elements with bus stop information
		if stop_name_label:
			stop_name_label.text = current_bus_stop.display_name
		
		if neighborhood_label:
			neighborhood_label.text = current_bus_stop.neighborhood.display_name
		
		update_direction_display()

func update_direction_display(specific_bus_line = null):
	# Step 3: Direction Button Logic
	if direction_button:
		# Check what directions are available across ALL lines
		var overall_directions = check_available_directions()
		
		if overall_directions.forward and overall_directions.backward:
			direction_button.disabled = false
			direction_button.text = "Change Direction"
		else:
			direction_button.disabled = true
			if overall_directions.forward:
				direction_button.text = "Forward Only"
			elif overall_directions.backward:
				direction_button.text = "Backward Only"
			else:
				direction_button.text = "No Travel"
	
	# Show terminus info for specific bus
	if specific_bus_line:
		var terminus = TransitSystem.get_direction_terminus(specific_bus_line)
		direction_label.text = "Next Bus to: " + terminus
	else:
		direction_label.text = ""
		
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
		
		# Find the current stop's index in this bus line
		var found_stop = false
		for i in range(TransitSystem.active_route_stops.size()):
			if TransitSystem.active_route_stops[i].display_name == current_bus_stop.display_name:
				TransitSystem.current_stop_index = i
				found_stop = true
				break
		
		if not found_stop:
			print("WARNING: Current stop not found in bus line, using default")
			# If going forward, start at beginning; if backward, start at end
			if TransitSystem.travel_direction == 1:
				TransitSystem.current_stop_index = 0
			else:
				TransitSystem.current_stop_index = TransitSystem.active_route_stops.size() - 1
		
		TransitSystem.advance_to_next_stop()
		
		# Change state to interior bus
		GameStateManager.change_to_state(GameStateManager.GameState.INTERIOR_BUS)

func _on_bus_spawn_timer_timeout():
	preview_next_bus()

func preview_next_bus():
	# STOP the bus spawn timer to prevent multiple calls
	if bus_spawn_timer:
		bus_spawn_timer.stop()
	
	if current_bus_stop and not current_bus_stop.connected_lines.is_empty():
		# Step 1: Bus Line Discovery - get ALL bus lines at this stop
		var all_bus_lines = current_bus_stop.connected_lines
		
		# Step 2: Filter to only lines that can go SOMEWHERE from this stop
		var valid_bus_lines = []
		for bus_line in all_bus_lines:
			var line_directions = check_available_directions(bus_line)
			# If this line can go in ANY direction from this stop, include it
			if line_directions.forward or line_directions.backward:
				valid_bus_lines.append(bus_line)
		
		if valid_bus_lines.size() > 0:
			# Step 4: Bus Preview/Spawning - pick random from ALL valid lines
			var random_index = randi() % valid_bus_lines.size()
			next_bus_line = valid_bus_lines[random_index]
			
			# Show preview UI
			show_bus_preview()
			
			# Start 3-second countdown before bus arrives
			preview_timer = Timer.new()
			preview_timer.wait_time = 3.0
			preview_timer.one_shot = true
			preview_timer.timeout.connect(spawn_previewed_bus)
			add_child(preview_timer)
			preview_timer.start()
			
			# Start countdown display updates
			start_countdown_display()
		else:
			# No valid buses - restart timer
			print("No buses can travel from this stop")
			bus_spawn_timer.start()

func start_countdown_display():
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 0.1
	countdown_timer.timeout.connect(update_countdown)
	add_child(countdown_timer)
	countdown_timer.start()

func update_countdown():
	if preview_timer and countdown_label:
		var time_left = preview_timer.time_left
		countdown_label.text = "Arriving in: " + str(ceil(time_left)) + "s"
		
		if time_left <= 0:
			countdown_timer.stop()
			countdown_timer.queue_free()

func spawn_previewed_bus():
	# Always spawn the bus
	var new_bus = spawn_specific_bus(next_bus_line)
	
	if player_has_signaled:
		new_bus.is_passing_through = false
	else:
		new_bus.is_passing_through = true
		show_missed_bus_message()
	
	# Clean up and reset
	cleanup_preview()

func spawn_specific_bus(bus_line):
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
	
	var direction_text = "Towards: " + TransitSystem.get_direction_terminus(bus_line)
	new_bus.set_direction_text(direction_text)
	
	# Display the bus line name
	new_bus.display_bus_line(bus_line.display_name)
	
	# Add to our active buses array for tracking
	active_buses.append(new_bus)
	
	# Return the bus so we can modify it
	return new_bus

func show_missed_bus_message():
	if next_bus_label:
		next_bus_label.text = "Bus passed - you missed it!"
		next_bus_label.modulate = Color.RED
		
		# Hide message after 2 seconds
		await get_tree().create_timer(2.0).timeout
		if next_bus_label:
			next_bus_label.modulate = Color.WHITE

func cleanup_preview():
	# Reset for next bus
	player_has_signaled = false
	next_bus_line = null
	
	# Hide preview panel
	if next_bus_panel:
		next_bus_panel.visible = false
	
	# Reset direction label to general direction
	update_direction_display()
	
	# Clean up timers
	if preview_timer:
		preview_timer.queue_free()
	if countdown_timer:
		countdown_timer.stop()
		countdown_timer.queue_free()
	
	# NOW restart the bus spawn timer for the next cycle
	if bus_spawn_timer:
		bus_spawn_timer.start()

func remove_bus(bus):
	# Remove from active buses array
	if bus in active_buses:
		active_buses.erase(bus)
	
	# Queue for deletion
	bus.queue_free()

func _on_direction_button_pressed():
	# If there's no active bus line, try to set one from the current stop
	if current_bus_stop and not current_bus_stop.connected_lines.is_empty():
		var bus_line = current_bus_stop.connected_lines[0]
		TransitSystem.set_active_bus_line(bus_line)
	else:
		print("BUS STOP: Cannot set active bus line - no connected lines at this stop")
	
	# Toggle direction in the TransitSystem
	TransitSystem.toggle_direction()

func _on_direction_changed(_new_direction):
	# Update the direction display
	update_direction_display()
	
	# Update existing buses with new direction text
	var terminus = TransitSystem.get_direction_terminus()
	for bus in active_buses:
		if bus.has_method("set_direction_text"):
			var direction_text = "Towards: " + terminus
			bus.set_direction_text(direction_text)

func check_available_directions(specific_bus_line = null):
	if not current_bus_stop or current_bus_stop.connected_lines.is_empty():
		return {"forward": false, "backward": false, "reason": "No bus lines available"}
	
	var can_go_forward = false
	var can_go_backward = false
	var restriction_reason = ""
	
	# If we have a specific bus line, check only that line
	var lines_to_check = []
	if specific_bus_line:
		lines_to_check = [specific_bus_line]
	else:
		lines_to_check = current_bus_stop.connected_lines
	
	# Check each bus line to see what directions are possible
	for bus_line in lines_to_check:
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
	
	return {
		"forward": can_go_forward,
		"backward": can_go_backward,
		"reason": restriction_reason
	}

# Audio functions
func play_bus_arrival():
	bus_stop_audio.stream = load("res://assets/audio/bus.ogg")
	bus_stop_audio.play()

func play_stop_announcement():
	bus_stop_audio.stream = load("res://assets/audio/bus_stop_announcement.ogg")
	bus_stop_audio.play()

func play_boarding_beep():
	bus_stop_audio.stream = load("res://assets/audio/beepbeeppediastrian.ogg")
	bus_stop_audio.play()

extends Node2D

@onready var bus_spawn_timer: Timer = $BusSpawnTimer
@onready var bus_spawn_position: Marker2D = $BusSpawnPosition
@onready var bus_despawn_position: Marker2D = $BusDespawnPosition
@export var bus_scene = preload("res://scenes/bus/bus.tscn")
@onready var character_player: CharacterBody2D = $CharacterPlayer

# UI elements (you'll need to add these to your scene)
@onready var stop_name_label = $StopNameLabel
@onready var neighborhood_label = $NeighborhoodLabel

var active_buses = []
var current_bus_stop = null

# Update the _ready function in bus_stop.gd

func _ready():
	# Get current bus stop from the transit system
	if TransitSystem.current_bus_stop:
		current_bus_stop = TransitSystem.current_bus_stop
	
	update_bus_stop_display()
	
	# Start the timer
	bus_spawn_timer.start()
	
func _process(_delta):
	# Check if any buses have reached the despawn position
	for bus in active_buses:
		if bus != null and bus.position.x <= bus_despawn_position.position.x:
			remove_bus(bus)
		if bus.can_player_board() and Input.is_action_pressed("Embark"):
			board_player(bus)
			break

func update_bus_stop_display():
	if current_bus_stop:
		# Update UI elements with bus stop information
		if stop_name_label:
			stop_name_label.text = current_bus_stop.display_name
		
		if neighborhood_label:
			neighborhood_label.text = current_bus_stop.neighborhood.display_name
		
		# You could also update the background or other visual elements
		# based on the neighborhood or other properties
		print("Now at bus stop: " + current_bus_stop.display_name)
	else:
		print("No current bus stop set!")

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
		bus.board_player(player)
		
		# Store the bus line in TransitSystem
		TransitSystem.current_bus_line = bus.bus_line
		
		# Set the active bus line and update the stops
		TransitSystem.set_active_bus_line(bus.bus_line)
		
		if bus.bus_line:
			print("Player boarded " + bus.bus_line.display_name)
		
		print("Advancing to next stop from: ", TransitSystem.current_stop_index)
		TransitSystem.advance_to_next_stop()
		print("Now at stop index: ", TransitSystem.current_stop_index)
		
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

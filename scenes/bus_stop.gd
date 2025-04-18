extends Node2D

@onready var bus_spawn_timer: Timer = $BusSpawnTimer
@onready var bus_spawn_position: Marker2D = $BusSpawnPosition
@onready var bus_despawn_position: Marker2D = $BusDespawnPosition
@export var bus_scene = preload("res://scenes/bus.tscn")
@onready var character_player: CharacterBody2D = $CharacterPlayer

# UI elements (you'll need to add these to your scene)
@onready var stop_name_label = $StopNameLabel
@onready var neighborhood_label = $NeighborhoodLabel

var active_buses = []
var current_bus_stop = null

func _ready():
	# Connect to TransitSystem signals
	TransitSystem.connect("bus_stop_changed", Callable(self, "_on_bus_stop_changed"))
	
	# Get current bus stop data
	#current_bus_stop = TransitSystem.get_current_bus_stop()
	var current_bus_stop = TransitSystem.set_current_bus_stop("test_bus_stop")
	update_bus_stop_display()
	
	# Connect the timer's timeout signal
	bus_spawn_timer.connect("timeout", Callable(self, "_on_bus_spawn_timer_timeout"))
	
	# Start the timer
	bus_spawn_timer.start()

func _process(delta):
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
			neighborhood_label.text = current_bus_stop.neighborhood
		
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
		
		# Optionally, update player state in the TransitSystem
		# This would depend on how you track which bus line this bus belongs to
		# TransitSystem.set_player_on_bus(bus.bus_line_id)

func _on_bus_spawn_timer_timeout():
	# Spawn a new bus
	spawn_bus()

func spawn_bus():
	# Instance the bus scene
	var new_bus = bus_scene.instantiate()
	
	# Set its position to the spawn position
	new_bus.position = bus_spawn_position.position
	
	# Pass the bus stop position to the bus
	new_bus.set_bus_stop_position($BusStopPosition.position.x)
	
	# If we have bus lines connected to this stop, we could
	# randomly select one and apply its properties to the bus
	if current_bus_stop and not current_bus_stop.connected_lines.is_empty():
		var random_index = randi() % current_bus_stop.connected_lines.size()
		var bus_line = current_bus_stop.connected_lines[random_index]
		
		# Apply bus line properties to the bus
		# new_bus.set_bus_line(bus_line)
		# This would require adding this method to your bus.gd script
	
	# Add the bus to the scene
	add_child(new_bus)
	
	# Add to our active buses array for tracking
	active_buses.append(new_bus)

func remove_bus(bus):
	# Remove from active buses array
	if bus in active_buses:
		active_buses.erase(bus)
	
	# Queue for deletion
	bus.queue_free()

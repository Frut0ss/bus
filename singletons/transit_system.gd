extends Node

# Current state tracking
var current_map_resource = null
var current_player_position = null
var current_bus_line = null
var current_bus_stop = null

# Resource collections
var bus_stops = {}
var bus_lines = {}
var bus_line_variants = {}

# Signal when the current bus stop changes
signal bus_stop_changed(new_stop)

# Initialize with a test bus stop (for development)
func _ready():
	# You might want to load a default/test bus stop here
	load_test_resources()

# Load a bus stop by ID
func load_bus_stop(stop_id):
	var path = "res://resources/bus_stops/" + stop_id + ".tres"
	if ResourceLoader.exists(path):
		var stop = load(path)
		bus_stops[stop_id] = stop
		return stop
	else:
		print("Error: Bus stop resource not found: " + path)
		return null

# Set the current bus stop (when player moves or boards/exits bus)
func set_current_bus_stop(stop_id):
	if stop_id in bus_stops:
		current_bus_stop = bus_stops[stop_id]
	else:
		current_bus_stop = load_bus_stop(stop_id)
	
	if current_bus_stop:
		emit_signal("bus_stop_changed", current_bus_stop)
		return true
	return false

# Get current bus stop details
func get_current_bus_stop():
	return current_bus_stop

# Get bus lines that stop at the current bus stop
func get_current_bus_stop_lines():
	if current_bus_stop:
		return current_bus_stop.connected_lines
	return []

# Load some test resources for development
func load_test_resources():
	# Create a test bus stop if it doesn't exist
	var test_stop = BusStopResource.new()
	test_stop.id = "test_stop"
	test_stop.display_name = "Test Bus Stop"
	test_stop.position = Vector2(500, 300)
	test_stop.is_landmark = true
	test_stop.neighborhood = "downtown"
	
	# Save to bus_stops dictionary
	bus_stops[test_stop.id] = test_stop
	
	# Set as current
	current_bus_stop = test_stop

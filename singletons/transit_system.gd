extends Node

# Current state tracking
var current_map_resource = null
var current_player_position = null
var current_bus_line = null
var current_bus_stop = null

# Bus route
var route_stops = []  # Array of bus stop resources in sequence
var current_stop_index = 0  # Current position in the route
var destination_index = 0   # Final destination index

# Resource collections
var bus_stops = {}
var bus_lines = {}
var bus_line_variants = {}

# Signal when the current bus stop changes
signal bus_stop_changed(new_stop)

# Called when the node enters the scene tree
func _ready():
	# We'll implement load_route_stops in a future step
	load_test_route()
	# Load bus lines 
	load_all_bus_lines()
	connect_lines_to_stops()
	# Print debug information
	print("TransitSystem initialized with:")
	print("- " + str(bus_stops.size()) + " bus stops")
	print("- " + str(bus_lines.size()) + " bus lines")

func load_test_route():
	# Clear existing route
	route_stops.clear()
	
	# Load stops
	var fleet_stop = load_bus_stop("fleet_street")
	var temple_stop = load_bus_stop("temple_lane")
	var meeting_stop = load_bus_stop("meeting_house_square")
	var dame_stop = load_bus_stop("dame_street")
	
	# Add them to the route in order
	if fleet_stop:
		route_stops.append(fleet_stop)
	if temple_stop:
		route_stops.append(temple_stop)
	if meeting_stop:
		route_stops.append(meeting_stop)
	if dame_stop:
		route_stops.append(dame_stop)
	
	# Set destination to the last stop
	destination_index = route_stops.size() - 1
	
	# Set current stop to the first one
	if route_stops.size() > 0:
		current_bus_stop = route_stops[0]
		current_stop_index = 0
	
	print("Loaded test route with ", route_stops.size(), " stops")
	for i in range(route_stops.size()):
		print("Stop ", i, ": ", route_stops[i].display_name)


# Add this function to TransitSystem.gd
func load_all_bus_lines():
	var line_ids = ["red_line", "blue_line", "green_line"]
	
	for line_id in line_ids:
		load_bus_line(line_id)
	
	print("Loaded " + str(bus_lines.size()) + " bus lines")
	return bus_lines

# Load a bus line by ID
func load_bus_line(line_id):
	var path = "res://resources/bus_lines/" + line_id + ".tres"
	if ResourceLoader.exists(path):
		print("Loading bus line from: " + path)
		
		# Try to load with ResourceLoader with a specific type hint
		var line = ResourceLoader.load(path, "Resource")
		
		if line:
			print("Successfully loaded line: " + line_id)
			bus_lines[line_id] = line
			
			# Only try to access stops if the stops property exists
			if line.stops :
				var stop_names = []
				for stop in line.stops:
					if stop:
						stop_names.append(stop.display_name)
				print(line.display_name + " stops: " + str(stop_names))
			else:
				print("WARNING: " + line_id + " has no stops or stops is null")
			
			return line
			
func connect_lines_to_stops():
	print("Connecting bus lines to stops...")
	
	# For each bus line, connect it to its stops
	for line_id in bus_lines:
		var line = bus_lines[line_id]
		
		# For each stop in the line, add the line to the stop's connected_lines
		for stop in line.stops:
			stop.add_line(line)
			print("Connected " + line.display_name + " to " + stop.display_name)

# Load a bus stop by ID
func load_bus_stop(stop_id):
	var path = "res://resources/bus_stops/" + stop_id + "_stop.tres"
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
		return current_bus_stop
	return null

# Get current bus stop details
func get_current_bus_stop():
	return current_bus_stop

# Get bus lines that stop at the current bus stop
func get_current_bus_stop_lines():
	if current_bus_stop:
		return current_bus_stop.connected_lines
	return []

func advance_to_next_stop():
	current_stop_index += 1
	print("Advanced to stop index: ", current_stop_index)
	
	# Safety check to avoid index out of bounds
	if route_stops.size() > 0 and current_stop_index < route_stops.size():
		current_bus_stop = route_stops[current_stop_index]
		print("New stop: ", current_bus_stop.display_name if current_bus_stop else "None")
		emit_signal("bus_stop_changed", current_bus_stop)
		return false  # Not at the end yet
	
	return true  # We're at the end

# Get the name of the current stop
func get_current_stop_name():
	if current_bus_stop and current_bus_stop.has("display_name"):
		return current_bus_stop.display_name
	return "Unknown Stop"

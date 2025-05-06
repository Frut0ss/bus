extends Node

# Current state tracking
var current_map_resource = null
var current_player_position = null
var current_bus_line = null
var current_bus_stop = null

var active_route_stops = [] # Stops on the current bus line
var active_bus_line = null  # The currently active bus lineources in sequence
var current_stop_index  # Current position in the route
var destination_index 

# Resource collections
var bus_stops = {}
var bus_lines = {}
var bus_line_variants = {}

# Signal when the current bus stop changes
signal bus_stop_changed(new_stop)

# Called when the node enters the scene tree
func _ready():
	# We'll implement load_route_stops in a future step
	initialize_transit_system()
	
	# Load bus lines 
	load_all_bus_lines()
	connect_lines_to_stops()
	# Print debug information
	print("TransitSystem initialized with:")
	print("- " + str(bus_stops.size()) + " bus stops")
	print("- " + str(bus_lines.size()) + " bus lines")

func initialize_transit_system():
	# Load all bus stops first
	load_all_bus_stops()
	
	# Check for starting and destination points
	var starting_stop = null
	var destination_stop = null
	
	# Find starting and destination stops
	for stop_id in bus_stops:
		var stop = bus_stops[stop_id]
		if stop.is_starting_point:
			starting_stop = stop
			print("Found starting point: " + stop.display_name)
		if stop.is_destination_point:
			destination_stop = stop
			print("Found destination point: " + stop.display_name)
	
	# Set current stop to the starting point
	if starting_stop:
		current_bus_stop = starting_stop
		print("Setting starting point to: " + starting_stop.display_name)
	else:
		print("Warning: No starting point found among bus stops!")
		
	# Set current_stop_index to -1 since we're not in a bus line yet
	# It will be set correctly when a bus line is activated
	current_stop_index = -1
	
# Helper function to load all bus stops
func load_all_bus_stops():
# Clear existing stops
	bus_stops.clear()

	# List of known stops to load
	var stop_ids = ["fleet_street", "temple_lane", "meeting_house_square", "dame_street"]

	# Load each stop
	for stop_id in stop_ids:
		var stop = load_bus_stop(stop_id)
		if stop:
			print("Loaded bus stop: " + stop.display_name)

	return bus_stops



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
	# Make sure we have an active bus line
	if not active_bus_line or active_route_stops.size() == 0:
		print("Error: Can't advance - no active bus line or stops")
		return true
	
	current_stop_index += 1
	print("Advanced to stop index: ", current_stop_index)
	
	# Safety check to avoid index out of bounds
	if current_stop_index < active_route_stops.size():
		current_bus_stop = active_route_stops[current_stop_index]
		print("New stop: ", current_bus_stop.display_name if current_bus_stop else "None")
		emit_signal("bus_stop_changed", current_bus_stop)
		
		# Check if we've reached a destination
		if current_bus_stop.is_destination_point:
			print("Reached destination stop!")
			return true
			
		return false  # Not at the end yet
	
	return true  # We're at the end
	
	
# Get the name of the current stop
func get_current_stop_name():
	if current_bus_stop and current_bus_stop.has("display_name"):
		return current_bus_stop.display_name
	return "Unknown Stop"

func find_stop_index_by_name(stop_name, stops_array):
	for i in range(stops_array.size()):
		if stops_array[i].display_name == stop_name:
			return i
	return -1

# Add this function to transit_system.gd
func set_active_bus_line(bus_line):
	active_bus_line = bus_line
	
	if bus_line:
		# Update active route stops to be the stops from this bus line
		active_route_stops = bus_line.stops.duplicate()
		
		# Find the index of the current stop in this line
		current_stop_index = -1
		for i in range(active_route_stops.size()):
			if active_route_stops[i] == current_bus_stop:
				current_stop_index = i
				break
		
		# If current stop wasn't found in the line, default to first stop
		if current_stop_index == -1 and active_route_stops.size() > 0:
			current_stop_index = 0
			current_bus_stop = active_route_stops[0]
		
		print("Set active bus line: " + bus_line.display_name)
		print("Active route has " + str(active_route_stops.size()) + " stops")
		print("Current stop index: " + str(current_stop_index))
	else:
		active_route_stops = []
		print("Warning: Tried to set null bus line")

func is_end_of_line(stop_resource, bus_line):
	# Check if the bus line is valid
	if not bus_line or not bus_line.stops or bus_line.stops.size() == 0:
		return false
		
	# Get the last stop in this bus line
	var last_stop = bus_line.stops[bus_line.stops.size() - 1]
	
	if stop_resource.display_name == last_stop.display_name:
		print("Stop " + stop_resource.display_name + " is the end of line for " + bus_line.display_name)
		return true
	
	# Check if the current stop is the last one
	return stop_resource.display_name == last_stop.display_name

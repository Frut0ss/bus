extends Node

var current_bus_line = null
var current_bus_stop = null

var active_route_stops = [] # Stops on the current bus line
var visited_stops = []
var active_bus_line = null  # The currently active bus line
var current_stop_index  # Current position in the route
var destination_index 

# Resource collections
var bus_stops = {}
var bus_lines = {}
var bus_line_variants = {}
var stop_id

signal destination_reached(stop_resource)
signal bus_stop_changed(new_stop)
signal stop_data_updated(stop_id)

# Called when the node enters the scene tree
func _ready():
	initialize_transit_system()
	load_all_bus_lines()
	connect_lines_to_stops()
	print("TransitSystem initialized successfully")

func initialize_transit_system():
	# Load all bus stops first
	load_all_bus_stops()
	
	# Check for starting and destination points
	var starting_stop
	var destination_stop
	
	# Find starting and destination stops
	for stop_id in bus_stops:
		var stop = bus_stops[stop_id]
		if stop.is_starting_point:
			starting_stop = stop
		if stop.is_destination_point:
			destination_stop = stop
	
	# Set current stop to the starting point
	if starting_stop:
		current_bus_stop = starting_stop
	else:
		print("Warning: No starting point found among bus stops!")
		
	# Set current_stop_index to -1 since we're not in a bus line yet
	current_stop_index = -1
	
# Helper function to load all bus stops
func load_all_bus_stops():
	bus_stops.clear()
	
	# Explicitly list your neighborhoods
	var neighborhoods = [
		"cabra-philsborough", 
		"north_side", 
		"phoenix_park", 
		"smithfield-stoneybatter", 
		"temple_bar"
	]
	
	# Load stops from each neighborhood
	for neighborhood in neighborhoods:
		load_stops_from_neighborhood(neighborhood)
		
	print("Loaded " + str(bus_stops.size()) + " bus stops from " + str(neighborhoods.size()) + " neighborhoods")
	return bus_stops

func load_stops_from_neighborhood(neighborhood):
	var dir_path = "res://resources/bus_stops/" + neighborhood
	var dir = DirAccess.open(dir_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				# Extract the stop_id from the filename (remove _stop.tres)
				stop_id = file_name.replace("_stop.tres", "")
				load_bus_stop(stop_id, neighborhood)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("Error: Could not open neighborhood directory: " + dir_path)

func load_all_bus_lines():
	var line_ids = ["red_line", "orange_line", "green_line"]
	
	for line_id in line_ids:
		load_bus_line(line_id)
	
	return bus_lines

# Load a bus line by ID
func load_bus_line(line_id):
	var path = "res://resources/bus_lines/" + line_id + ".tres"
	if ResourceLoader.exists(path):
		# Try to load with ResourceLoader with a specific type hint
		var line = ResourceLoader.load(path, "Resource")
		
		if line:
			bus_lines[line_id] = line
			
			# Only try to access stops if the stops property exists
			if not line.stops:
				print("WARNING: " + line_id + " has no stops or stops is null")
			
			return line
			
func connect_lines_to_stops():
	# For each bus line, connect it to its stops
	for line_id in bus_lines:
		var line = bus_lines[line_id]
		
		# For each stop in the line, add the line to the stop's connected_lines
		for stop in line.stops:
			stop.add_line(line)

# Load a bus stop by ID
func load_bus_stop(stop_id, neighborhood):
	var path = "res://resources/bus_stops/" + neighborhood + "/" + stop_id + "_stop.tres"
	if ResourceLoader.exists(path):
		var stop = load(path)
		
		# Store the neighborhood in the resource if it has that property
		if stop.neighborhood.display_name:
			stop.neighborhood.display_name = neighborhood
		
		# Store using the full ID to avoid collisions between neighborhoods
		var full_id = neighborhood + "/" + stop_id
		bus_stops[full_id] = stop
		return stop
	else:
		print("Error: Bus stop resource not found: " + path)
		return null

# Set the current bus stop (when player moves or boards/exits bus)
func set_current_bus_stop(stop_id):
	# Check if this is already a full_id (neighborhood/stop_id)
	if stop_id in bus_stops:
		current_bus_stop = bus_stops[stop_id]
	else:
		# If it's not a full_id, we need to find which neighborhood has this stop
		var found = false
		for full_id in bus_stops.keys():
			if full_id.ends_with("/" + stop_id):
				current_bus_stop = bus_stops[full_id]
				found = true
				break
				
		if not found:
			print("Error: Could not find stop_id: " + stop_id)
			return null
	
	if current_bus_stop:
		add_visited_stop(current_bus_stop)
		emit_signal("bus_stop_changed", current_bus_stop)
		return current_bus_stop
	return null

func advance_to_next_stop():
	# Make sure we have an active bus line
	if not active_bus_line or active_route_stops.size() == 0:
		print("Error: Can't advance - no active bus line or stops")
		return true
	
	current_stop_index += 1
	
	# Safety check to avoid index out of bounds
	if current_stop_index < active_route_stops.size():
		current_bus_stop = active_route_stops[current_stop_index]
		emit_signal("bus_stop_changed", current_bus_stop)
		
		# Check if we've reached a destination
		if current_bus_stop.is_destination_point:
			print("Destination reached!")
			return true
			
		return false  # Not at the end yet
	
	return true  # We're at the end

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
	else:
		active_route_stops = []
		print("Warning: Tried to set null bus line")

func is_end_of_line(stop_resource, bus_line):
	# Check if the bus line is valid
	if not bus_line or not bus_line.stops or bus_line.stops.size() == 0:
		return false
		
	# Get the last stop in this bus line
	var last_stop = bus_line.stops[bus_line.stops.size() - 1]
	
	# Check if the current stop is the last one
	var is_last = stop_resource.display_name == last_stop.display_name
	
	return is_last

func register_stop(stop_node, stop_id):
	# Store reference to stop
	if bus_stops.has(stop_id):
		# Send stop data to the node
		stop_node.set_stop_data(bus_stops[stop_id])
	else:
		print("Warning: Stop ID not found: " + stop_id)
		
func update_all_stops():
	# Emit signal for all stops to update
	for stop_id in bus_stops:
		emit_signal("stop_data_updated", stop_id)

func check_destination_reached():
	if not current_bus_stop:
		return false
		
	if current_bus_stop.is_destination_point:
		print("Destination reached!")
		# Emit a signal that other systems can listen for
		emit_signal("destination_reached", current_bus_stop)
		return true
		
	return false

func add_visited_stop(stop_resource):
	# Only add if not already the last stop
	if visited_stops.size() == 0 or visited_stops[-1] != stop_resource:
		visited_stops.append(stop_resource)
		print("TransitSystem: Added visited stop: " + stop_resource.display_name)
		print("TransitSystem: Total visited stops: " + str(visited_stops.size()))
	else:
		print("Couldn't add visited stop")

extends Node2D

# Dictionary to map stop resources to node references
var stop_nodes = {}
# Dictionary of map node references by name
var map_stop_nodes = {}
@onready var player_marker: Node2D = $Background/PlayerMarker
@onready var destination_marker: Node2D = $Background/DestinationMarker

var player_path = null

# Constants for visualization
const ROUTE_LINE_WIDTH = 4
const DEFAULT_LINE_COLOR = Color(0.7, 0.7, 0.7, 0.7)  # Gray with transparency
const PLAYER_PATH_COLOR = Color(1, 0, 0, 0.7)  # Fully opaque red
const PLAYER_PATH_WIDTH = 8  # Much wider than normal routes

# Called when the node enters the scene tree for the first time
func _ready():
	# First, collect all stop nodes from the scene
	for child in $Background.get_children():
		if child.is_in_group("map_stops") or "stop" in child.name.to_lower():
			var node_name = child.name.to_lower()
			map_stop_nodes[node_name] = child
	
	# Now connect each stop resource to its visual node
	connect_stops_to_nodes()
	
	# Connect to TransitSystem signals
	TransitSystem.connect("bus_stop_changed", Callable(self, "_on_bus_stop_changed"))
	
	# Draw bus routes FIRST (so they're below the player path)
	draw_all_bus_routes()
	
	# Initialize player visualization LAST (so it's on top)
	setup_player_visualization()
	
	# Update map display
	update_map_display()
	
	# Print debug info
	print("Map scene initialized with " + str(stop_nodes.size()) + " stops")

# Connect stop resources to their visual nodes
func connect_stops_to_nodes():
	# For each stop in the transit system
	for stop_id in TransitSystem.bus_stops:
		var stop_resource = TransitSystem.bus_stops[stop_id]
		
		# Find a matching node for this stop
		var matched_node = find_matching_node(stop_id, stop_resource)
		
		if matched_node:
			# Connect resource to node
			stop_nodes[stop_resource] = matched_node
		else:
			print("WARNING: No matching node found for stop: " + stop_id)

func find_matching_node(stop_id, stop_resource):
	# Extract just the stop name part from the full ID
	var parts = stop_id.split("/")
	var stop_name = parts[1] if parts.size() > 1 else stop_id
	
	# Try to match by exact name first
	var node_name = stop_name.to_lower().replace("_", " ")
	if map_stop_nodes.has(node_name):
		return map_stop_nodes[node_name]
	
	# If that fails, try a fuzzy match
	for map_node_name in map_stop_nodes.keys():
		# Try removing _stop suffix if present
		if stop_name.ends_with("_stop"):
			var base_name = stop_name.substr(0, stop_name.length() - 5).to_lower().replace("_", " ")
			if map_node_name == base_name:
				return map_stop_nodes[map_node_name]
		
		# Try other fuzzy matching techniques if needed
		# e.g., check if the node name is contained within the stop name
		if map_node_name in stop_name.to_lower().replace("_", " "):
			return map_stop_nodes[map_node_name]
	
	return null

# Setup player visualization elements
func setup_player_visualization():
	# Remove any existing player path
	if player_path != null:
		if player_path.is_inside_tree():
			player_path.queue_free()
		player_path = null
	
	# Create a new player path
	player_path = Line2D.new()
	player_path.name = "PlayerPath" # Give it a distinct name
	player_path.width = PLAYER_PATH_WIDTH
	player_path.default_color = PLAYER_PATH_COLOR
	player_path.z_index = 100  # Make sure it renders above everything else
	player_path.begin_cap_mode = Line2D.LINE_CAP_ROUND
	player_path.end_cap_mode = Line2D.LINE_CAP_ROUND
	player_path.antialiased = true
	$Background.add_child(player_path)
	print("Created player path: " + str(player_path.get_path()))
	
	# Update the player path with all visited stops from TransitSystem
	update_player_path()
	
	# Make sure the current stop is included
	if TransitSystem.current_bus_stop and not TransitSystem.visited_stops.has(TransitSystem.current_bus_stop):
		TransitSystem.add_visited_stop(TransitSystem.current_bus_stop)
		update_player_path()

# Draw all bus routes on the map
func draw_all_bus_routes():
	# Clear any existing route lines, but keep player path
	for child in $Background.get_children():
		if child is Line2D and (not player_path or child != player_path):
			child.queue_free()
	
	# Draw each bus line
	for line_id in TransitSystem.bus_lines:
		var bus_line = TransitSystem.bus_lines[line_id]
		if bus_line and bus_line.stops and bus_line.stops.size() >= 2:
			draw_bus_route(bus_line, line_id)
			print("Drawing route for: " + line_id)
		else:
			print("WARNING: Skipping route for " + line_id + " (invalid data)")

# Draw a single bus route on the map
func draw_bus_route(bus_line, line_id):
	# Create a new Line2D node for this route
	var route_line = Line2D.new()
	route_line.width = ROUTE_LINE_WIDTH
	route_line.z_index = 0  # Below player path
	
	# Get route color from the bus_line resource
	var line_color = DEFAULT_LINE_COLOR
	
	# Check if the resource has a color property
	if bus_line.color:
		line_color = bus_line.color
		# Add some transparency if the color is fully opaque
		if line_color.a > 0.9:
			line_color.a = 0.7
	
	# Set the line color
	route_line.default_color = line_color
	
	# Add points for each stop in the line
	for stop in bus_line.stops:
		if stop_nodes.has(stop):
			var node_position = stop_nodes[stop].position
			route_line.add_point(node_position)
	
	# Only add the route if it has at least 2 points
	if route_line.get_point_count() >= 2:
		$Background.add_child(route_line)
		print("Added route line with " + str(route_line.get_point_count()) + " points")
	else:
		route_line.queue_free()
		print("WARNING: Route line had fewer than 2 points")

# Update the map display based on current transit system state
func update_map_display():
	# Update stop labels
	for stop_resource in stop_nodes.keys():
		var node = stop_nodes[stop_resource]
		node.set_bus_stop_resource(stop_resource)
	
	# Update player marker position
	update_player_marker()
	
	# Update destination marker
	update_destination_marker()

# Update player marker position to current stop
func update_player_marker():
	if player_marker and TransitSystem.current_bus_stop:
		var current_node = stop_nodes.get(TransitSystem.current_bus_stop)
		if current_node:
			player_marker.global_position = current_node.global_position
			player_marker.visible = true
		else:
			player_marker.visible = false

# Update destination marker position
func update_destination_marker():
	if destination_marker:
		# Find a destination stop
		var destination_stop = find_destination_stop()
		
		if destination_stop:
			var dest_node = stop_nodes.get(destination_stop)
			if dest_node:
				destination_marker.global_position = dest_node.global_position
				destination_marker.visible = true
				return
		
		# If we didn't find a destination or its node, hide the marker
		destination_marker.visible = false

# Find a destination stop in the transit system
func find_destination_stop():
	for stop_id in TransitSystem.bus_stops:
		var stop = TransitSystem.bus_stops[stop_id]
		if stop.is_destination_point:
			return stop
	return null

# Update the visual representation of the player's path
func update_player_path():
	if player_path:
		player_path.clear_points()
		
		# Debug the path points before adding
		var point_strings = []
		
		# Add points for all visited stops from the TransitSystem
		for stop in TransitSystem.visited_stops:
			if stop_nodes.has(stop):
				var node_position = stop_nodes[stop].position
				point_strings.append(stop.display_name + " at " + str(node_position))
				player_path.add_point(node_position)
		
		print("Updated player path with points: " + str(point_strings))
		print("Player path now has " + str(player_path.get_point_count()) + " points")
	else:
		print("ERROR: Tried to update player path but it doesn't exist!")

# Signal handler for when the bus stop changes in the transit system
func _on_bus_stop_changed(new_stop):
	print("Bus stop changed to: " + new_stop.display_name)
	
	# Updates will be handled through TransitSystem signals
	update_player_path()
	
	# Update the map display to reflect the new stop
	update_map_display()

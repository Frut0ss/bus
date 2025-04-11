extends Node2D

# Variables for the stops and route
var base_position := Vector2.ZERO  # Base position of the route (starting point)
var stops := []  # List to store stop positions

var route_length = 500  # Total route length (in pixels)
var num_stops = 5  # Number of stops along the route
var route_color = Color(0.0, 0.45, 0.85)  # Color of the route line (blue)
var journey_color = Color(1, 0, 0)  # Color for the journey line (red)
var player_path = [0, 1, 2, 3, 4]  # The player's path (array of stop indices)

var current_stop_index = 0  # Current stop index the player is at
var is_animating = false  # Whether the animation is in progress

# Reference to the player marker node, ensure 'MapStop' is correctly assigned
@onready var player_marker := $Background/MapStop  

var route_lines = []  # List to store route lines

# Node to draw the circles at each stop
class StopCircle extends Node2D:
	var radius := 10  # Increased size of the stop circle
	var color := Color(0.0, 1.0, 0.0)  # Bright green color for the circles

	# Method to draw the circle
	func _draw():
		# Draw the circle at the node's position
		draw_circle(Vector2.ZERO, radius, color)

# When the scene is ready (initialized), this method runs
func _ready():
	# Set the base position of the player marker (start position)
	base_position = player_marker.global_position
	
	# Setup the stops along the route
	setup_stops()

	# Draw the route and stops
	draw_route()

	# Restore the current stop from the GameState
	current_stop_index = GameStateManager.current_stop_index if GameStateManager.current_stop_index < player_path.size() else 0
	player_marker.global_position = stops[player_path[current_stop_index]]

	# If coming from a bus, start moving the player
	if GameStateManager.has_boarded_bus:
		move_to_next_stop()

# Setup the stops along a straight route
func setup_stops():
	stops = []  # Clear any existing stops
	var distance_between_stops = route_length / (num_stops - 1)  # Calculate the distance between each stop
	
	# Add the stops to the list, spaced evenly along the route
	for i in range(num_stops):
		stops.append(base_position + Vector2(i * distance_between_stops, 0))

# Draw the route (line) and add the circles at each stop
func draw_route():
	# Create the full route line
	var line = Line2D.new()
	add_child(line)  # Add the line to the main node
	line.z_index = 10  # Ensure it's above the background
	line.width = 6.0  # Line width
	line.default_color = route_color  # Set the line color

	# Add the points for the route (the stops) to the line
	for stop in stops:
		line.add_point(stop)

	# Add the large circles for each stop
	for i in range(stops.size()):
		var stop_circle = StopCircle.new()  # Create a new circle for each stop
		stop_circle.position = stops[i]  # Set the position of the circle at the stop
		stop_circle.name = "StopCircle_" + str(i)  # Name the circles (StopCircle_0, StopCircle_1, ...)
		stop_circle.color = Color(0.0, 1.0, 0.0)  # Set the circle color to bright green
		add_child(stop_circle)  # Add the circle to the scene

	# Save the route lines for future reference
	route_lines.append(line)

# Animate the player's movement to the next stop
func move_to_next_stop():
	# Check if the player can move to the next stop (there are more stops in the path)
	if current_stop_index < player_path.size() - 1 and not is_animating:
		is_animating = true  # Set the animation state to true

		var start = stops[player_path[current_stop_index]]  # Starting position
		current_stop_index += 1  # Move to the next stop
		var target = stops[player_path[current_stop_index]]  # Target stop position

		# Create a new line to animate the journey (show where the player is moving)
		var journey_line = Line2D.new()
		journey_line.default_color = journey_color  # Set the journey line color to red
		journey_line.width = 8.0  # Line width
		journey_line.z_index = 15  # Ensure it's above other lines
		add_child(journey_line)
		journey_line.add_point(start)  # Add the start point to the journey line

		# Create a tween for the animation
		var tween = create_tween()
		tween.set_parallel(true)  # Set the tween to run in parallel
		var duration = 2.0  # Animation duration (in seconds)
		tween.tween_property(player_marker, "global_position", target, duration)  # Move the player marker

		# Animate the journey line step by step
		var steps = 20  # Number of steps for the journey line animation
		for i in range(1, steps + 1):
			var t = float(i) / steps  # Calculate the interpolation factor
			var inter = start.lerp(target, t)  # Get the intermediate position
			tween.tween_callback(func():
				journey_line.add_point(inter)  # Add the intermediate point to the journey line
			).set_delay(t * duration)  # Set delay for each step

		# After the animation finishes, update the current stop index and reset the animation state
		tween.tween_callback(func():
			is_animating = false
			GameStateManager.current_stop_index = current_stop_index  # Save the new stop index
		)

# Handle input events (such as pressing the space key to move to the next stop)
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		move_to_next_stop()  # Move to the next stop when the space key is pressed

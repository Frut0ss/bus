extends Node2D

@export var fleet_stop: BusStopResource
@export var temple_bar_stop: BusStopResource
@export var meeting_house_stop: BusStopResource
@export var dame_street_stop: BusStopResource

@onready var fleet_node := $Background/Fleet
@onready var temple_bar_node := $Background/TempleBar
@onready var meeting_house := $Background/Meetinghouse
@onready var dame_street := $Background/Damestreet
@onready var player_marker := $Background/PlayerMarker

var is_animating := false
var stops := []
var win_scene = preload("res://scenes/win.tscn")

func _ready():
	# Assign resources to nodes if present
	if fleet_stop:
		fleet_node.set_bus_stop_resource(fleet_stop)
	if temple_bar_stop:
		temple_bar_node.set_bus_stop_resource(temple_bar_stop)
	if meeting_house_stop:
		meeting_house.set_bus_stop_resource(meeting_house_stop)
	if dame_street_stop:
		dame_street.set_bus_stop_resource(dame_street_stop)

	# Define stops in route order
	stops = [
		fleet_node.global_position,
		temple_bar_node.global_position,
		meeting_house.global_position,
		dame_street.global_position
	]

	# Set player marker to current stop from TransitSystem
	var current_stop_index = TransitSystem.current_stop_index
	if current_stop_index < stops.size():
		player_marker.global_position = stops[current_stop_index]
	else:
		# Fallback to first stop
		player_marker.global_position = stops[0]

	# Draw full route
	draw_route_line(stops)
	
	#move_to_next_stop()
	
	draw_journey_progress(current_stop_index)

func draw_route_line(stop_positions: Array):
	var line = Line2D.new()
	line.default_color = Color(0.0, 0.45, 0.85)
	line.width = 6.0
	line.z_index = 1
	add_child(line)

	for pos in stop_positions:
		line.add_point(pos)

func draw_journey_progress(current_index):
	# Create the line object
	var journey_line = Line2D.new()
	journey_line.default_color = Color(1, 0, 0)  # Red color for journey
	journey_line.width = 8.0
	journey_line.z_index = 15
	add_child(journey_line)
	
	# If we're only at the first stop, just add that point
	if current_index == 0:
		journey_line.add_point(stops[0])
		return
	
	# Add only the first point initially
	journey_line.add_point(stops[0])
	
	# Create a tween for animation
	var tween = create_tween()
	var duration = 0.75  # Total animation duration in seconds
	
	# Calculate delay between adding each point
	var delay_per_point = duration / current_index
	
	# Animate adding each subsequent point
	for i in range(1, current_index + 1):
		if i < stops.size():
			# Create a closure to capture the current index
			var add_point_func = func():
				journey_line.add_point(stops[i])
			
			# Add the point after a delay
			tween.tween_callback(add_point_func).set_delay(delay_per_point)
#
#func _input(event):
	#if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		#move_to_next_stop()

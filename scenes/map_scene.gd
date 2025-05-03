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
var current_stop_index := 0
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

	# Set initial player marker position
	current_stop_index = GameStateManager.current_stop_index if GameStateManager.current_stop_index < stops.size() else 0
	player_marker.global_position = stops[current_stop_index]

	# Draw full route
	draw_route_line(stops)

	if GameStateManager.has_boarded_bus:
		move_to_next_stop()

func draw_route_line(stop_positions: Array):
	var line = Line2D.new()
	line.default_color = Color(0.0, 0.45, 0.85)
	line.width = 6.0
	line.z_index = 10
	add_child(line)

	for pos in stop_positions:
		line.add_point(pos)

# Update your move_to_next_stop function
func move_to_next_stop():
	if current_stop_index < stops.size() - 1 and not is_animating:
		is_animating = true

		var start = stops[current_stop_index]
		current_stop_index += 1  # Increase the stop index
		var target = stops[current_stop_index]

		var journey_line = Line2D.new()
		journey_line.default_color = Color(1, 0, 0)  # Red color for journey
		journey_line.width = 8.0
		journey_line.z_index = 15
		add_child(journey_line)
		journey_line.add_point(start)

		var tween = create_tween().set_parallel(true)
		var duration = 2.0
		tween.tween_property(player_marker, "global_position", target, duration)

		var steps = 20
		for i in range(1, steps + 1):
			var t = float(i) / steps
			var inter = start.lerp(target, t)
			tween.tween_callback(func():
				journey_line.add_point(inter)
			).set_delay(t * duration)

		tween.tween_callback(func():
			is_animating = false
			GameStateManager.current_stop_index = current_stop_index

			# Debugging line to check if we reached the last stop
			print("Current Stop Index: ", current_stop_index, " Last Stop Index: ", stops.size() - 1)

			# Check if we reached the 4th stop (index 3 in 0-based index)
			if current_stop_index == stops.size() - 1:
				# Change to GAME_WON state in the GameStateManager
				GameStateManager.change_to_state(GameStateManager.GameState.GAME_WON)  # Corrected reference
		)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		move_to_next_stop()

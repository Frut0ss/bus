class_name BusStopResource
extends Resource

@export var id: String
@export var display_name: String
@export var position: Vector2
@export var is_landmark: bool = false
@export var neighborhood: String

# We can't directly export arrays of custom resources in Godot,
# so we'll store them internally
var connected_lines = []

func _init(p_id = "", p_display_name = "", p_position = Vector2.ZERO, p_is_landmark = false, p_neighborhood = ""):
	id = p_id
	display_name = p_display_name
	position = p_position
	is_landmark = p_is_landmark
	neighborhood = p_neighborhood

func add_line(line_resource):
	if not line_resource in connected_lines:
		connected_lines.append(line_resource)

func remove_line(line_resource):
	if line_resource in connected_lines:
		connected_lines.erase(line_resource)

func get_line_ids():
	var ids = []
	for line in connected_lines:
		ids.append(line.id)
	return ids

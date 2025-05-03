class_name BusStopResource
extends Resource

@export var id: String
@export var display_name: String
@export var position: Vector2
@export var is_landmark: bool = false
@export var neighborhood: NeighborhoodResource

# We can't directly export arrays of custom resources in Godot,
# so we'll store them internally
var connected_lines = []


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

class_name BusStopResource
extends Resource

@export var id: String
@export var display_name: String
@export var position: Vector2
@export var is_landmark: bool = false
@export var neighborhood: Resource  # Reference to neighborhood
@export var is_starting_point: bool = false
@export var is_destination_point: bool = false
# Runtime-only property - not saved to file
var connected_lines = []

func _init():
	# Initialize with empty array
	connected_lines = []

func add_line(line_resource):
	if not connected_lines:
		connected_lines = []
	
	if line_resource not in connected_lines:
		connected_lines.append(line_resource)
		print("Added " + line_resource.display_name + " to " + display_name)

func remove_line(line_resource):
	if line_resource in connected_lines:
		connected_lines.erase(line_resource)

func get_line_ids():
	var ids = []
	for line in connected_lines:
		ids.append(line.id)
	return ids

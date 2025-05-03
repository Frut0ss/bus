extends Node2D

var bus_stop_resource: Resource

# Assign a BusStopResource to this stop
func set_bus_stop_resource(resource: Resource) -> void:
	bus_stop_resource = resource
	update_display()

# Update any UI elements or logic based on the resource
func update_display() -> void:
	if has_node("Label") and bus_stop_resource:
		var label = $Label
		if label is Label:
			label.text = bus_stop_resource.display_name

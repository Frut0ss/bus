@tool
extends BaseStop
@onready var label: Label = $Label

func _ready():
	super._ready()

# Assign a BusStopResource to this stop
func set_bus_stop_resource(resource: Resource) -> void:
	stop_resource = resource
	update_display()

# Update any UI elements or logic based on the resource
func update_display() -> void:
	if stop_resource:
			label.text = stop_resource.display_name

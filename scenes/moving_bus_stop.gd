# In moving_bus_stop.gd
extends Node2D

@onready var bus_stop_name: Label = $Name  # If your label is named "Name"
var stop_resource: BusStopResource

func _ready():
	# Optional: Add debugging to verify the scene is instantiated
	print("Bus stop created: " + name)
	print("Label for the bus stop" + str(bus_stop_name))

func set_stop_data(bus_stop_res):
	stop_resource = bus_stop_res
	
	# Debug print to verify function is called
	print("Setting stop data: " + bus_stop_res.display_name)
	
	if bus_stop_name:
		bus_stop_name.text = bus_stop_res.display_name
	else:
		# Debug if Label node is missing
		print("ERROR: Label node not found in bus stop")
		
		# Create a label if it doesn't exist
		var new_label = Label.new()
		new_label.name = "Label"
		new_label.text = bus_stop_res.display_name
		new_label.position = Vector2(0, -50)  # Position above the stop sign
		new_label.modulate = Color(1, 1, 0)  # Yellow for visibility
		add_child(new_label)
		bus_stop_name = new_label

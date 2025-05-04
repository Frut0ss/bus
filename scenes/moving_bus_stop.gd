# Add to moving_bus_stop.gd
extends Node2D

@onready var bus_stop_name: Label = $Name
@onready var area: Area2D = $Area2D
var stop_resource: BusStopResource
var player_in_range = false

func _ready():
	# Connect area signals
	area.connect("body_entered", Callable(self, "_on_body_entered"))
	area.connect("body_exited", Callable(self, "_on_body_exited"))
	

func set_stop_data(bus_stop_res):
	stop_resource = bus_stop_res
	
	if bus_stop_name:
		bus_stop_name.text = bus_stop_res.display_name
	else:
		print("ERROR: Label node not found in bus stop")
		
		# Create a label if it doesn't exist
		var new_label = Label.new()
		new_label.name = "Label"
		new_label.text = bus_stop_res.display_name
		new_label.position = Vector2(0, -50)
		add_child(new_label)
		bus_stop_name = new_label

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		# Visual feedback that player can disembark here
		modulate = Color(1.2, 1.2, 0.8)  # Slightly highlight the stop
		print("Player can disembark at: " + stop_resource.display_name)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		# Return to normal appearance
		modulate = Color(1, 1, 1)

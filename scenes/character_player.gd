extends Area2D  # Or whatever node you're using

var on_bus = false
var current_bus = null

func _ready() -> void:
	add_to_group("player")

func _process(delta):
	# Check for boarding input when near a bus
	if not on_bus:
		# If player presses the embark button/key while not on a bus
		if Input.is_action_just_pressed("embark"):  # Define this action in Project Settings
			# The actual boarding is handled by the bus's body_entered signal
			pass
	else:
		# Player is on a bus, check for disembark input when bus is stopped
		if Input.is_action_just_pressed("disembark"):  # Define this action in Project Settings
			if current_bus and current_bus.at_bus_stop:
				current_bus.disembark_player()
				
func set_on_bus(status):
	on_bus = status
	
func set_current_bus(bus):
	current_bus = bus

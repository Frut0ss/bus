extends Area2D  # Or whatever node you're using

var on_bus = false
var current_bus = null
var nearby_bus = null  # Almacena el bus cercano

func _ready() -> void:
	add_to_group("player")
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("area_exited", Callable(self, "_on_area_exited"))
	
func _on_area_entered(area):
	if area.is_in_group("bus") and area.at_bus_stop:
		nearby_bus = area
		set_current_bus(area)

func _on_area_exited(area):
	if area == nearby_bus:
		nearby_bus = null
		set_current_bus(null)

func _process(delta):
	if not on_bus and nearby_bus and nearby_bus.at_bus_stop:
		if Input.is_action_just_pressed("embark"):
			print("¡Subiendo al bus!")
			set_on_bus(true)
			current_bus.resume()
			hide()  # O remove_child(self), si quieres quitarlo completamente
		elif Input.is_action_just_pressed("disembark"):
			print("Decidiste no subir al bus.")
			current_bus.resume()

func set_on_bus(status):
	on_bus = status
	
func set_current_bus(bus):
	current_bus = bus

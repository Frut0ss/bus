extends Area2D

@export var speed = 700  # Pixels per second
var stopped: bool = false
var has_stopped: bool = false
var at_bus_stop: bool = false

func _ready():
	add_to_group("bus")

func _process(delta):
	if not stopped:
		position.x -= speed * delta

func stop_at_bus_stop():
	stopped = true
	has_stopped = true
	at_bus_stop = true

func resume():
	stopped = false
	at_bus_stop = false

# Lógica para cuando el jugador baja (puede ser llamada desde player)
func disembark_player():
	# Esto se puede adaptar luego
	print("Jugador ha bajado del bus.")

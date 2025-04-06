extends Node2D

@onready var bus_spawn_timer: Timer = $BusSpawnTimer
@onready var bus_spawn_position: Marker2D = $BusSpawnPosition
@onready var bus_despawn_position: Marker2D = $BusDespawnPosition
@onready var bus_stop_position: Marker2D = $BusStopPosition
@export var bus_scene = preload("res://scenes/bus.tscn")

var active_buses = []

func _ready():
	bus_spawn_timer.connect("timeout", Callable(self, "_on_bus_spawn_timer_timeout"))
	bus_spawn_timer.start()

func _process(delta):
	for bus in active_buses:
		if bus != null:
			# Si no se ha detenido y pasa por la parada
			if not bus.has_stopped and bus.position.x <= bus_stop_position.position.x:
				bus.stop_at_bus_stop()
				print("Bus detenido en la parada")

			# Si ya pasó la parada y llega al punto de eliminación
			elif bus.position.x <= bus_despawn_position.position.x:
				remove_bus(bus)

func _on_bus_spawn_timer_timeout():
	spawn_bus()

func spawn_bus():
	var new_bus = bus_scene.instantiate()
	new_bus.position = bus_spawn_position.position
	add_child(new_bus)
	active_buses.append(new_bus)

	bus_spawn_timer.stop() # Detenemos el timer para evitar que siga spawneando


func remove_bus(bus):
	if bus in active_buses:
		active_buses.erase(bus)
	bus.queue_free()

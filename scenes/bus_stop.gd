extends Node2D

@onready var bus_spawn_timer: Timer = $BusSpawnTimer
@onready var bus_spawn_position: Marker2D = $BusSpawnPosition
@onready var bus_despawn_position: Marker2D = $BusDespawnPosition
@export var bus_scene = preload("res://scenes/bus.tscn")
@onready var character_player: CharacterBody2D = $CharacterPlayer

var active_buses = []

func _ready():
	# Connect the timer's timeout signal
	bus_spawn_timer.connect("timeout", Callable(self, "_on_bus_spawn_timer_timeout"))
	
	# Start the timer
	bus_spawn_timer.start()

func _process(delta):
	# Check if any buses have reached the despawn position
	for bus in active_buses:
		if bus != null and bus.position.x <= bus_despawn_position.position.x:
			remove_bus(bus)
		if bus.can_player_board() and Input.is_action_pressed("Embark"):
			board_player(bus)
			break
			
func board_player(bus):
	var player = character_player
	if player:
		bus.board_player(player)

func _on_bus_spawn_timer_timeout():
	# Spawn a new bus
	spawn_bus()

func spawn_bus():
	# Instance the bus scene
	var new_bus = bus_scene.instantiate()
	
	# Set its position to the spawn position
	new_bus.position = bus_spawn_position.position
	
	# Pass the bus stop position to the bus
	new_bus.set_bus_stop_position($BusStopPosition.position.x)
	
	# Add the bus to the scene
	add_child(new_bus)
	
	# Add to our active buses array for tracking
	active_buses.append(new_bus)

func remove_bus(bus):
	# Remove from active buses array
	if bus in active_buses:
		active_buses.erase(bus)
	
	# Queue for deletion
	bus.queue_free()

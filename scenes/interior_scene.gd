extends Node2D

@export var scroll_speed = 300.0
@export var interior_bus_stop_scene: PackedScene 

@onready var bus_stop_spawner: Marker2D = $BusStopSpawner
@onready var container: Node2D = $StopsContainer
@onready var timer: Timer = $Timer

var is_moving = true
var time_since_last_spawn = 0.0
var upcoming_stops = []
var stops_spawned = 0
var bus_stop_despawn_threshold = 2300  # X position to remove passed stops

func _ready():
	# Get route data from TransitSystem
	setup_upcoming_stops()
	
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
func setup_upcoming_stops():
	upcoming_stops.clear()
	stops_spawned = 0
	
	# Start from current stop index and add remaining stops
	for i in range(TransitSystem.current_stop_index, TransitSystem.route_stops.size()):
		upcoming_stops.append(TransitSystem.route_stops[i])
	
	# If we have remaining stops, spawn the first one immediately
	if upcoming_stops.size() > 0:
		spawn_next_stop()

func _process(delta):
	if is_moving:
		# Move the parallax background
		$ParallaxBackground.scroll_offset.x += scroll_speed * delta
		
		## Update timer for stop spawning
		#time_since_last_spawn += delta
		#
		## Check if it's time to spawn the next stop
		#if timer and stops_spawned < upcoming_stops.size():
			#spawn_next_stop()
			#time_since_last_spawn = 0
		
		# Check for stops that need to be removed (passed by)
		check_stops_to_remove()
	
	# Handle disembarking input
	if Input.is_action_just_pressed("disembark"):
		handle_disembark()

func spawn_next_stop():
	if stops_spawned >= upcoming_stops.size():
		return
		
	var stop_resource = upcoming_stops[stops_spawned]
	var stop_instance = interior_bus_stop_scene.instantiate()
	
	# Add to scene first
	stop_instance.position = bus_stop_spawner.position
	container.add_child(stop_instance)
	
	# Wait a frame to ensure _ready is called
	await get_tree().process_frame
	
	# Now set the data
	stop_instance.set_stop_data(stop_resource)
	
	stops_spawned += 1
	print("Spawned stop: " + stop_resource.display_name)

func check_stops_to_remove():
	if container:
		for stop in container.get_children():
			# Move the stop along with the background
			stop.position.x += scroll_speed * get_process_delta_time()
			
			# Remove if it's past the threshold
			if stop.position.x > bus_stop_despawn_threshold:
				stop.queue_free()
				
			# Check if we've reached the destination
			if TransitSystem.current_stop_index == TransitSystem.destination_index:
				# We've reached the destination!
				GameStateManager.change_to_state(GameStateManager.GameState.GAME_WON)

func handle_disembark():
	var container = get_node_or_null("StopsContainer")
	if container and container.get_child_count() > 0:
		var current_stop = container.get_child(0)
		
		# Check if we're close enough to disembark at this stop
		if current_stop.position.x > 700 and current_stop.position.x < 1200:
			print("Disembarking at: " + current_stop.stop_resource.display_name)
			GameStateManager.change_to_state(GameStateManager.GameState.MAP_VIEW)


func _on_timer_timeout():
	if is_moving and stops_spawned < upcoming_stops.size():
		spawn_next_stop()

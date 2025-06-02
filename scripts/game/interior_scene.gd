extends Node2D

@export var scroll_speed = 300.0
@export var interior_bus_stop_scene: PackedScene 

@onready var bus_stop_spawner: Marker2D = $BusStopSpawner
@onready var container: Node2D = $StopsContainer
@onready var timer: Timer = $Timer
@onready var next_stop_label: Label = $NextStopLabel
@onready var city_spawner: Node2D = $CitySpawner
@onready var stop_button: Area2D = $StopButton

var player_near_button = false
var button_enabled = false
var is_moving = true
var time_since_last_spawn = 0.0
var upcoming_stops = []
var stops_spawned = 0
var bus_stop_despawn_threshold = 2300  # X position to remove passed stops
var stop_requested = false

func _ready():
	# Get route data from TransitSystem
	setup_upcoming_stops()
	
	if next_stop_label:
		next_stop_label.visible = false
	
	if city_spawner:
		city_spawner.move_speed = scroll_speed

	if city_spawner and city_spawner.has_method("pause_spawning"):
	# City spawner is ready to receive commands
		pass
	
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	

func setup_upcoming_stops():
	upcoming_stops.clear()
	stops_spawned = 0
	
	# Check if we have an active bus line
	if TransitSystem.active_bus_line and TransitSystem.active_route_stops.size() > 0:
		
		# Get the current stop index from TransitSystem
		var current_index = TransitSystem.current_stop_index
		
		# First, always add the current stop to show where we are
		if current_index >= 0 and current_index < TransitSystem.active_route_stops.size():
			upcoming_stops.append(TransitSystem.active_route_stops[current_index])
			
			# Add stops based on direction
			if TransitSystem.travel_direction == 1:
				# Going FORWARD - add stops after current index
				for i in range(current_index + 1, TransitSystem.active_route_stops.size()):
					upcoming_stops.append(TransitSystem.active_route_stops[i])
			else:
				# Going BACKWARD - add stops before current index (in reverse order)
				for i in range(current_index - 1, -1, -1):
					upcoming_stops.append(TransitSystem.active_route_stops[i])
			
			print("Added " + str(upcoming_stops.size()) + " total stops")
			
			# Check if we're already at a terminus
			var at_terminus = false
			if TransitSystem.travel_direction == 1 and current_index == TransitSystem.active_route_stops.size() - 1:
				at_terminus = true
				print("At the end of the line (forward) - will auto-disembark")
			elif TransitSystem.travel_direction == -1 and current_index == 0:
				at_terminus = true
				print("At the beginning of the line (backward) - will auto-disembark")
			
			if at_terminus:
				call_deferred("auto_disembark")
		else:
			print("Current index invalid: " + str(current_index))
	else:
		# Fallback if no bus line is active
		print("No active bus line, cannot determine upcoming stops")
	
	# If we have remaining stops, spawn the first one immediately
	if upcoming_stops.size() > 0:
		spawn_next_stop()
	else:
		print("No upcoming stops found!")
		
func schedule_final_stop_disembark():
	# Create a flag to track when we need to disembark
	var final_stop_tracker = Timer.new()
	final_stop_tracker.wait_time = 10.0  # Adjust based on how long it takes to reach the next stop
	final_stop_tracker.one_shot = true
	final_stop_tracker.connect("timeout", Callable(self, "auto_disembark"))
	add_child(final_stop_tracker)
	final_stop_tracker.start()


func _process(delta): 
	if is_moving:
		# Move the parallax background
		$ParallaxBackground.scroll_offset.x += scroll_speed * delta
		update_current_stop_position()
		check_stops_to_remove()
		update_disembark_ui()
		
		# Request stop when near button and press Embark
		if Input.is_action_just_pressed("Embark") and player_near_button and not stop_requested:
			request_stop()

func request_stop():
	stop_requested = true
	update_label("Stop requested - will disembark at next stop")
	print("Stop requested!")

func spawn_next_stop():
	if stops_spawned >= upcoming_stops.size():
		return
		
	var stop_resource = upcoming_stops[stops_spawned]
	var stop_instance = interior_bus_stop_scene.instantiate()
	
	# Add to scene at the spawn position
	stop_instance.position = bus_stop_spawner.position
	container.add_child(stop_instance)
	
	# Wait a frame to ensure _ready is called
	await get_tree().process_frame
	
	# Now set the data
	stop_instance.set_stop_data(stop_resource)
	
	stops_spawned += 1
	print("Spawned stop: " + stop_resource.display_name)
	
	# If player requested stop, disembark at this stop
	if stop_requested:
		# Wait for stop to reach disembark position, then disembark
		await wait_for_stop_to_reach_center(stop_instance)
		handle_disembark(stop_resource)  # <-- Pass the specific stop resource
		stop_requested = false

func wait_for_stop_to_reach_center(stop_instance):
	# Wait until the stop reaches the disembark zone
	while stop_instance.position.x < 700:
		await get_tree().process_frame

func check_stops_to_remove():
	if container:
		var reached_last_stop = false
		
		for stop in container.get_children():
			# Move the stop along with the background
			stop.position.x += scroll_speed * get_process_delta_time()
			
			# Check if this is the last stop and it's in the disembark range
			if stop.stop_resource == TransitSystem.active_route_stops.back() and stop.position.x > 700 and stop.position.x < 1200:
				reached_last_stop = true
			
			# Remove if it's past the threshold
			if stop.position.x > bus_stop_despawn_threshold:
				stop.queue_free()
		
		# If we've reached the last stop, trigger auto-disembark
		if reached_last_stop:
			auto_disembark()
			
		# Check if we've reached the destination
		if TransitSystem.current_bus_stop and TransitSystem.current_bus_stop.is_destination_point:
			# We've reached the destination!
			GameStateManager.change_to_state(GameStateManager.GameState.GAME_WON)

func handle_disembark(specific_stop_resource = null):
	var current_stop_resource = specific_stop_resource
	
	# If no specific stop provided, find one in disembark range (old behavior)
	if not current_stop_resource:
		for stop in get_tree().get_nodes_in_group("bus_stops"):
			if stop.position.x > 700 and stop.position.x < 1200:
				current_stop_resource = stop.stop_resource
				break
	
	if current_stop_resource:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("start_walking"):
			player.start_walking()
		# Stop the parallax movement
		is_moving = false
		
		if city_spawner and city_spawner.has_method("pause_spawning"):
			city_spawner.pause_spawning()
		
		update_label("Disembarking at " + current_stop_resource.display_name + "...")
		
		# Create a small delay to show the disembarking animation
		await get_tree().create_timer(1.5).timeout
		
		# Update TransitSystem with our new location
		TransitSystem.current_bus_stop = current_stop_resource
		
		
		# If we have an active bus line, find this stop's index in that line
		if TransitSystem.active_bus_line and TransitSystem.active_route_stops.size() > 0:
			var stop_index = -1
			for i in range(TransitSystem.active_route_stops.size()):
				if TransitSystem.active_route_stops[i].display_name == current_stop_resource.display_name:
					stop_index = i
					break
			
			if stop_index != -1:
				TransitSystem.current_stop_index = stop_index
			else:
				print("WARNING: Could not find stop in active bus line: " + current_stop_resource.display_name)
		else:
			print("No active bus line to update stop index")
		
		# Check if we've reached a destination
		if current_stop_resource.is_destination_point:
			print("Reached destination stop!")
			GameStateManager.change_to_state(GameStateManager.GameState.GAME_WON)
		else:
			# Change scene to map view or bus stop
			GameStateManager.change_to_state(GameStateManager.GameState.MAP_VIEW)


func _on_timer_timeout():
	if is_moving and stops_spawned < upcoming_stops.size():
		spawn_next_stop()

func update_disembark_ui():
	# Only check for terminus stops for auto-disembark
	for stop in get_tree().get_nodes_in_group("bus_stops"):
		if stop.position.x > 700 and stop.position.x < 1200:
			var current_stop_name = stop.stop_resource.display_name
			
			# Check if this is a terminus stop based on travel direction
			if TransitSystem.active_route_stops.size() > 0:
				var is_end_terminus = false
				var is_start_terminus = false
				
				# Check if this is the last stop (forward terminus)
				var last_stop = TransitSystem.active_route_stops[TransitSystem.active_route_stops.size() - 1]
				if stop.stop_resource.display_name == last_stop.display_name:
					is_end_terminus = true
				
				# Check if this is the first stop (backward terminus)
				var first_stop = TransitSystem.active_route_stops[0]
				if stop.stop_resource.display_name == first_stop.display_name:
					is_start_terminus = true
				
				# Auto-disembark at terminus
				if (TransitSystem.travel_direction == 1 and is_end_terminus) or (TransitSystem.travel_direction == -1 and is_start_terminus):
					var direction_name = "forward" if TransitSystem.travel_direction == 1 else "backward"
					update_label("End of line (" + direction_name + "): " + current_stop_name)
					call_deferred("auto_disembark")
			break

func update_label(text: String):
	if next_stop_label:
		next_stop_label.text = text
		next_stop_label.visible = true

# Add this new function to interior_scene.gd
func update_current_stop_position():
	# Check all bus stops in the scene
	for stop in get_tree().get_nodes_in_group("bus_stops"):
		# Define the "current stop zone" - slightly wider than disembark zone
		# to ensure we catch the stop early enough
		if stop.position.x > 600 and stop.position.x < 1300:
			var current_stop_resource = stop.stop_resource
			
			# Update TransitSystem's current stop index and stop resource
			if TransitSystem.active_route_stops.size() > 0:
				for i in range(TransitSystem.active_route_stops.size()):
					if TransitSystem.active_route_stops[i].display_name == current_stop_resource.display_name:
						# Only update if this is a new stop
						if TransitSystem.current_stop_index != i:
							TransitSystem.current_stop_index = i
							TransitSystem.current_bus_stop = current_stop_resource
							TransitSystem.add_visited_stop(TransitSystem.current_bus_stop)
							
							# Check if this is a terminus based on direction
							var reached_terminus = false
							
							if TransitSystem.travel_direction == 1:
								# Going forward - check if we're at the last stop
								var last_index = TransitSystem.active_route_stops.size() - 1
								if i == last_index:
									print("Reached the end of the line (forward)!")
									reached_terminus = true
							else:
								# Going backward - check if we're at the first stop
								if i == 0:
									print("Reached the beginning of the line (backward)!")
									reached_terminus = true
							
							if reached_terminus:
								call_deferred("auto_disembark")
			break  # Only process one stop at a time

func auto_disembark():
	# Wait a moment to show the stop before disembarking
	await get_tree().create_timer(2.0).timeout
	
	# Stop the parallax movement
	is_moving = false
	
	if city_spawner and city_spawner.has_method("pause_spawning"):
		city_spawner.pause_spawning()
	# Visual feedback
	if next_stop_label:
		update_label("End of line: " + TransitSystem.current_bus_stop.display_name)
		next_stop_label.visible = true
	
	# Create a small delay to show the disembarking animation
	await get_tree().create_timer(1.5).timeout
	
	# Check if we've reached a destination
	if TransitSystem.current_bus_stop.is_destination_point:
		print("Reached destination stop!")
		GameStateManager.change_to_state(GameStateManager.GameState.GAME_WON)
	else:
		# Change scene to map view or bus stop
		GameStateManager.change_to_state(GameStateManager.GameState.MAP_VIEW)

func _on_stop_button_body_entered(body):
	if body.is_in_group("player"):
		player_near_button = true

func _on_stop_button_body_exited(body):
	if body.is_in_group("player"):
		player_near_button = false

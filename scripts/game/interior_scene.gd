extends Node2D

@export var scroll_speed = 300.0
@export var interior_bus_stop_scene: PackedScene 

@onready var bus_stop_spawner: Marker2D = $BusStopSpawner
@onready var container: Node2D = $StopsContainer
@onready var timer: Timer = $Timer
@onready var next_stop_label: Label = $NextStopLabel

var is_moving = true
var time_since_last_spawn = 0.0
var upcoming_stops = []
var stops_spawned = 0
var bus_stop_despawn_threshold = 2300  # X position to remove passed stops

func _ready():
	# Get route data from TransitSystem
	setup_upcoming_stops()
	
	if next_stop_label:
		next_stop_label.visible = false
	
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	

func setup_upcoming_stops():
	upcoming_stops.clear()
	stops_spawned = 0
	
	# Check if we have an active bus line
	if TransitSystem.active_bus_line and TransitSystem.active_route_stops.size() > 0:
		print("Using stops from active bus line: " + TransitSystem.active_bus_line.display_name)
		
		# Get the current stop index from TransitSystem
		var current_index = TransitSystem.current_stop_index
		print("Current stop index: " + str(current_index))
		print("Travel direction: " + ("Forward" if TransitSystem.travel_direction == 1 else "Backward"))
		
		# First, always add the current stop to show where we are
		if current_index >= 0 and current_index < TransitSystem.active_route_stops.size():
			upcoming_stops.append(TransitSystem.active_route_stops[current_index])
			print("Added current stop: " + TransitSystem.active_route_stops[current_index].display_name)
			
			# Add stops based on direction
			if TransitSystem.travel_direction == 1:
				# Going FORWARD - add stops after current index
				for i in range(current_index + 1, TransitSystem.active_route_stops.size()):
					upcoming_stops.append(TransitSystem.active_route_stops[i])
					print("Added upcoming stop (forward): " + TransitSystem.active_route_stops[i].display_name)
			else:
				# Going BACKWARD - add stops before current index (in reverse order)
				for i in range(current_index - 1, -1, -1):
					upcoming_stops.append(TransitSystem.active_route_stops[i])
					print("Added upcoming stop (backward): " + TransitSystem.active_route_stops[i].display_name)
			
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
	print("Scheduled disembark at final stop")

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
		update_current_stop_position()
		# Check for stops that need to be removed (passed by)
		check_stops_to_remove()
		update_disembark_ui()
	# Handle disembarking input
	if Input.is_action_just_pressed("Disembark"):
		handle_disembark()



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
			print("Reached final stop - auto-disembarking")
			auto_disembark()
			
		# Check if we've reached the destination
		if TransitSystem.current_bus_stop and TransitSystem.current_bus_stop.is_destination_point:
			# We've reached the destination!
			GameStateManager.change_to_state(GameStateManager.GameState.GAME_WON)

func handle_disembark():
	var can_disembark = false
	var current_stop_resource = null
	
	# Find any stop in disembark range
	for stop in get_tree().get_nodes_in_group("bus_stops"):
		if stop.position.x > 700 and stop.position.x < 1200:
			can_disembark = true
			current_stop_resource = stop.stop_resource
			break
	
	if can_disembark and current_stop_resource:
		print("Disembarking at: " + current_stop_resource.display_name)
		
		# Stop the parallax movement
		is_moving = false
		
		# Visual feedback
		if next_stop_label:
			next_stop_label.text = "Disembarking at " + current_stop_resource.display_name + "..."
		
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
				print("Updated transit system stop index to: " + str(stop_index))
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
	var can_disembark = false
	var is_terminus_stop = false
	var current_stop_name = ""
	
	# Check all bus stops in the scene
	for stop in get_tree().get_nodes_in_group("bus_stops"):
		# If any stop is in the disembark range (center of screen)
		if stop.position.x > 700 and stop.position.x < 1200:
			can_disembark = true
			current_stop_name = stop.stop_resource.display_name
			
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
				
				# Determine if we should auto-disembark based on direction
				if TransitSystem.travel_direction == 1 and is_end_terminus:
					# Going forward and reached the end
					is_terminus_stop = true
					print("Reached forward terminus: " + current_stop_name)
				elif TransitSystem.travel_direction == -1 and is_start_terminus:
					# Going backward and reached the beginning
					is_terminus_stop = true
					print("Reached backward terminus: " + current_stop_name)
			
			if next_stop_label:
				if is_terminus_stop:
					var direction_name = "forward" if TransitSystem.travel_direction == 1 else "backward"
					next_stop_label.text = "End of line (" + direction_name + "): " + current_stop_name
					# Trigger auto-disembark
					call_deferred("auto_disembark")
				else:
					next_stop_label.text = "Press Q to disembark at " + current_stop_name
				next_stop_label.visible = true
			
			break  # Only process one stop at a time
	
	# Hide the label if no stop is in range
	if !can_disembark and next_stop_label:
		next_stop_label.visible = false

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
							print("Updated current stop to: " + current_stop_resource.display_name + " (index: " + str(i) + ")")
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
	
	print("Auto-disembarking at end of line")
	
	# Stop the parallax movement
	is_moving = false
	
	# Visual feedback
	if next_stop_label:
		next_stop_label.text = "End of line: " + TransitSystem.current_bus_stop.display_name
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

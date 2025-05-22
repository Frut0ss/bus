extends Area2D
# Bus properties
@export var speed = 700  # Pixels per second
var bus_stop_position_x = 0
var at_bus_stop = false
var stop_timer: Timer
@export var stop_time:float = 1.0
var player_in_range = false  # New variable to track if player is in range
var player = CharacterBody2D
var is_leaving = false
@onready var sitting_position: Marker2D = $SittingPosition
@onready var boarding_position: Marker2D = $BoardingPosition
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var direction_label: Label = $DirectionLabel
@onready var line_label: Label = $LineLabel

var bus_line = null
var direction_text = "Towards: Unknown"


func _ready():
	# Create the timer programmatically
	stop_timer = Timer.new()
	stop_timer.one_shot = true
	stop_timer.wait_time = stop_time
	stop_timer.connect("timeout", Callable(self, "_on_stop_timer_timeout"))
	add_child(stop_timer)
	
	# Disconnect any existing connections first
	if is_connected("body_entered", Callable(self, "_on_body_entered")):
		disconnect("body_entered", Callable(self, "_on_body_entered"))
	
	if is_connected("body_exited", Callable(self, "_on_body_exited")):
		disconnect("body_exited", Callable(self, "_on_body_exited"))
	
	# Now connect signals
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _process(delta):
	# Check for overlapping bodies to debug
	var overlapping_bodies = get_overlapping_bodies()
	var player_found = false
	
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			player_found = true
			if not player_in_range:
				player_in_range = true
				
				# Show boarding prompt if at bus stop
				if at_bus_stop:
					display_boarding_prompt(true)
	
	# Check if player was in range but is no longer found
	if player_in_range and not player_found:
		player_in_range = false
		display_boarding_prompt(false)
	if not at_bus_stop:
		# Move the bus leftward when not at a stop
		position.x -= speed * delta
		
		# Check if we've reached the bus stop position
		if position.x <= bus_stop_position_x + 10 and position.x >= bus_stop_position_x - 10:
			# Bus has reached the stop
			arrive_at_stop()
		if player != null and is_leaving and position.x < -200:  # Adjust value based on bus size
			is_leaving = false
			GameStateManager.change_to_state(GameStateManager.GameState.INTERIOR_BUS)

func arrive_at_stop():
	# Snap to exact position to avoid jitter
	position.x = bus_stop_position_x
	at_bus_stop = true
	
	# Visual indicator that bus is stopped
	modulate = Color(1.0, 1.0, 0.7)  # Slightly yellow tint
	
	# Start the stop timer
	stop_timer.start()

func _on_stop_timer_timeout() -> void:
	# Resume movement
	at_bus_stop = false
	
	# Reset visual indicator
	modulate = Color(1.0, 1.0, 1.0)  # Back to normal color
	
	# Force a small movement to ensure it's out of the stopping zone
	position.x -= 20.0

func set_bus_stop_position(pos_x):
	bus_stop_position_x = pos_x

# New functions for player detection
func _on_body_entered(body):
	# Check if it's the player
	if body.is_in_group("player"):
		player_in_range = true
		
		# Optional: Show a visual indicator that boarding is possible
		if at_bus_stop:
			display_boarding_prompt(true)

func _on_body_exited(body):
	# Check if it's the player
	if body.is_in_group("player"):
		player_in_range = false
		
		# Optional: Hide boarding prompt
		display_boarding_prompt(false)

func display_boarding_prompt(display):
	if display:
		if can_player_board():
			print("Press E to board the bus - " + bus_line.display_name + " " + direction_text)
			modulate = Color(1.0, 1.0, 1.0)  # Normal color
		else:
			# Check why we can't board
			var current_stop = TransitSystem.current_bus_stop
			if current_stop and bus_line:
				var current_stop_index = -1
				for i in range(bus_line.stops.size()):
					if bus_line.stops[i].display_name == current_stop.display_name:
						current_stop_index = i
						break
				
				if current_stop_index != -1:
					var direction_name = "forward" if TransitSystem.travel_direction == 1 else "backward"
					var at_terminus = false
					
					if TransitSystem.travel_direction == 1 and current_stop_index == bus_line.stops.size() - 1:
						at_terminus = true
					elif TransitSystem.travel_direction == -1 and current_stop_index == 0:
						at_terminus = true
					
					if at_terminus:
						print("Cannot board " + bus_line.display_name + " - already at " + direction_name + " terminus")
						modulate = Color(0.7, 0.7, 0.7, 0.8)  # Grayed out
					else:
						print("Cannot board " + bus_line.display_name + " - direction issue")
						modulate = Color(0.8, 0.8, 0.8, 0.8)  # Slightly grayed
				else:
					print("Cannot board " + bus_line.display_name + " - stop not found in line")
					modulate = Color(0.7, 0.0, 0.0, 0.8)  # Red tint
			else:
				print("Cannot board - missing bus line or current stop data")
				modulate = Color(0.7, 0.0, 0.0, 0.8)  # Red tint
	else:
		print("Boarding prompt hidden")
		modulate = Color(1.0, 1.0, 1.0)  # Reset to normal colorr
		
func display_bus_line(line_name):
	print("Attempting to display line name: " + line_name)
	line_label.text = line_name

func board_player(player_node):
	# Store reference to player
	player = player_node
	
	# Remove player from its parent
	var player_parent = player.get_parent()
	if player_parent:
		player_parent.remove_child(player)
	
	# Add player as child of bus
	add_child(player)
	
	
	# Reset player's position relative to bus
	player.position = boarding_position.position
	
	var tween = create_tween()
	# Move the player up (into the bus)
	tween.tween_property(player, "position", Vector2(sitting_position.position.x, sitting_position.position.y), 2)
	# Play the animation on the player's AnimationPlayer
	if player.has_node("AnimationPlayer"):
			var player_anim = player.get_node("AnimationPlayer")
			
			# Disconnect any previous connections to prevent errors
			if player_anim.is_connected("animation_finished", Callable(self, "_on_player_animation_finished")):
				player_anim.disconnect("animation_finished", Callable(self, "_on_player_animation_finished"))
			
			# Connect the signal
			player_anim.connect("animation_finished", Callable(self, "_on_player_animation_finished"))
			
			# Play the animation
			player_anim.play("boarding")
			
			print("Playing boarding animation on player")


func can_player_board():
	if not (player_in_range and at_bus_stop and bus_line):
		return false
	
	var current_stop = TransitSystem.current_bus_stop
	if not current_stop:
		return false
	
	# Find the current stop's position in this bus line
	var current_stop_index = -1
	for i in range(bus_line.stops.size()):
		if bus_line.stops[i].display_name == current_stop.display_name:
			current_stop_index = i
			break
	
	if current_stop_index == -1:
		print("Current stop not found in bus line: " + bus_line.display_name)
		return false
	
	# Check if we can travel in the current direction
	var can_travel = false
	
	if TransitSystem.travel_direction == 1:
		# Going forward - check if there are stops ahead
		can_travel = current_stop_index < bus_line.stops.size() - 1
	else:
		# Going backward - check if there are stops behind
		can_travel = current_stop_index > 0
	
	if not can_travel:
		print("Cannot board " + bus_line.display_name + " - no stops in " + 
			  ("forward" if TransitSystem.travel_direction == 1 else "backward") + " direction")
	
	return can_travel

func _on_player_animation_finished(anim_name):
	print("Player animation finished:", anim_name)
	# Start the bus moving again
	at_bus_stop = false
	is_leaving = true

func set_direction_text(text):
	direction_text = text
	direction_label.text = direction_text

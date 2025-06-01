extends CharacterBody2D


@onready var sprites: Node2D = $Sprites
var sprites_scale:float = -1
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var move_speed: float = 300.0
var current_state = "idle"
@export var jump_strength: float = -900.0
@export var gravity: float = 980.0
var is_on_ground: bool = true
var facing_direction = 1  # Add initial value

func _ready():
	# Start with idle animation
	play_animation("idle")

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		is_on_ground = false
	else:
		is_on_ground = true
	
		# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_strength
	
	handle_movement(delta)
	
	# Move the character
	move_and_slide()
	
	# Update animations based on movement
	if abs(velocity.x) > 0 and is_on_ground:
		start_walking()
	elif is_on_ground:
		start_idle()
		



func handle_movement(delta: float) -> void:
	var horizontal_input = Input.get_axis("left", "right")
	
	# Store facing direction based on input
	if horizontal_input != 0:
		facing_direction = sign(horizontal_input)
		sprites.scale.x = facing_direction * sprites_scale
	velocity.x = horizontal_input * move_speed
	
func play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		current_state = anim_name
		animation_player.play(anim_name)
	else:
		print("Animation not found: " + anim_name)

# Call this when player boards a bus
func start_boarding():
	play_animation("boarding")

# Call this when player is moving between stops  
func start_walking():
	play_animation("walk")

# Call this when player is waiting/stationary
func start_idle():
	play_animation("idle")

func _on_player_animation_finished(anim_name):
	# After boarding animation, switch to idle
	if anim_name == "boarding":
		start_idle()

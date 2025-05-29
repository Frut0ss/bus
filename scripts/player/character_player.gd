extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var current_state = "idle"

func _ready():
	# Start with idle animation
	play_animation("idle")

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

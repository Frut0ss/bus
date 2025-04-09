extends CharacterBody2D
func _ready() -> void:
	add_to_group("player")

func _process(delta):
	pass
	


func _on_player_animation_finished(anim_name: StringName) -> void:
	pass # Replace with function body.

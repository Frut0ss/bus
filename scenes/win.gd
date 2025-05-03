extends Node2D

@onready var panel = $Panel  # Make sure the label is inside a panel
@onready var label = $Panel/Label  # Label is inside the panel

func _ready() -> void:
	if label:
		label.text = "You Won!!!"  # Set the win message
	

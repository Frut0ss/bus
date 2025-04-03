# game_state_manager.gd
extends Node

enum GameState {MAP_VIEW, BUS_STOP, INTERIOR_BUS}
var current_state = GameState.MAP_VIEW

func _process(delta):
	match current_state:
		GameState.MAP_VIEW:
			if Input.is_action_just_pressed("click"):
				change_to_state(GameState.BUS_STOP)
		GameState.BUS_STOP:
			if Input.is_action_just_pressed("click"):
				change_to_state(GameState.INTERIOR_BUS)
		GameState.INTERIOR_BUS:
			if Input.is_action_just_pressed("click"):
				change_to_state(GameState.MAP_VIEW)

func change_to_state(new_state):
	current_state = new_state
	
	match new_state:
		GameState.MAP_VIEW:
			#SceneTransitionManager.fade_to_scene("map")
			SceneTransitionManager.change_scene("map")
		GameState.BUS_STOP:
			#SceneTransitionManager.fade_to_scene("bus_stop")
			SceneTransitionManager.change_scene("bus_stop")
		GameState.INTERIOR_BUS:
			#SceneTransitionManager.fade_to_scene("bus_stop")
			SceneTransitionManager.change_scene("interior_bus")
		# Handle other states...

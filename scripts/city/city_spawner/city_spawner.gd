extends Node2D
@export var move_speed: float = 300.0

# Building categories
@export_group("Buildings")
@export var georgian_houses: Array[PackedScene] = []
@export var shops: Array[PackedScene] = []
@export var modern_buildings: Array[PackedScene] = []
@export var landmarks: Array[PackedScene] = []

@export_group("Street Elements") 
@export var lamp_posts: Array[PackedScene] = []
@export var trees: Array[PackedScene] = []

# Spawn settings
@export_group("Spawn Settings")
@export var building_spawn_interval: float = 1.5
@export var lamp_spawn_interval: float = 2.5

@onready var building_spawner = $BuildingSpawner
@onready var lamp_spawner = $LampSpawner
@onready var container = $CityContainer
@onready var despawn_line = $CityDespawnLine

var building_timer: Timer
var lamp_timer: Timer
var is_paused = false

func _ready():
	setup_timers()

func setup_timers():
	building_timer = Timer.new()
	building_timer.wait_time = building_spawn_interval
	building_timer.timeout.connect(_spawn_building)
	add_child(building_timer)
	building_timer.start()
	
	lamp_timer = Timer.new()
	lamp_timer.wait_time = lamp_spawn_interval
	lamp_timer.timeout.connect(_spawn_street_element)
	add_child(lamp_timer)
	lamp_timer.start()

func _spawn_building():
	if is_paused:
		return
	
	# Weighted random selection
	var rand = randf()
	var scene_to_spawn: PackedScene
	
	if rand < 0.5 and georgian_houses.size() > 0:
		# 50% Georgian houses
		scene_to_spawn = georgian_houses[randi() % georgian_houses.size()]
	elif rand < 0.7 and shops.size() > 0:
		# 20% shops
		scene_to_spawn = shops[randi() % shops.size()]
	elif rand < 0.9 and modern_buildings.size() > 0:
		# 20% modern buildings
		scene_to_spawn = modern_buildings[randi() % modern_buildings.size()]
	elif landmarks.size() > 0:
		# 10% landmarks
		scene_to_spawn = landmarks[randi() % landmarks.size()]
	
	if scene_to_spawn:
		spawn_element(scene_to_spawn, building_spawner.position)

func _spawn_street_element():
	if is_paused:
		return
	
	var rand = randf()
	var scene_to_spawn: PackedScene
	
	if rand < 0.7 and lamp_posts.size() > 0:
		# 70% lamp posts
		scene_to_spawn = lamp_posts[randi() % lamp_posts.size()]
	elif trees.size() > 0:
		# 30% trees
		scene_to_spawn = trees[randi() % trees.size()]
	
	if scene_to_spawn:
		spawn_element(scene_to_spawn, lamp_spawner.position)

func spawn_element(scene: PackedScene, spawn_pos: Vector2):
	var instance = scene.instantiate()
	instance.position = spawn_pos
	container.add_child(instance)

# Special spawning for stop-specific buildings (for later use)
func spawn_special_building(building_scene: PackedScene):
	if building_scene:
		spawn_element(building_scene, building_spawner.position)

func _process(delta):
	if not is_paused:
		for child in container.get_children():
			child.position.x += move_speed * delta
			
			if child.position.x > despawn_line.position.x:
				child.queue_free()

func pause_spawning():
	is_paused = true
	building_timer.stop()
	lamp_timer.stop()

func resume_spawning():
	is_paused = false
	building_timer.start()
	lamp_timer.start()

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

var last_spawned_shop: PackedScene = null
var building_timer: Timer
var lamp_timer: Timer
var is_paused = false

func _ready():
	setup_timers()
	initial_spawn()  # Add this line

func initial_spawn():
	# Spawn buildings in the visible area around the player
	# Player sees roughly from x = 0 to x = 1920 (screen width)
	
	# Spawn 2-3 buildings in visible area
	var visible_positions = [0, 800, 1700]  # x positions in visible area
	
	for pos_x in visible_positions:
		# Only spawn if we have a random chance (so not every position fills)
		if randf() < 0.7:  # 70% chance to spawn at each position
			_spawn_initial_building(Vector2(pos_x, building_spawner.position.y))
		
		# Also chance for street elements
		if randf() < 0.4:  # 40% chance for lamp/tree
			_spawn_initial_street_element(Vector2(pos_x + 100, lamp_spawner.position.y))

func _spawn_building():
	if is_paused:
		return
	spawn_random_building(building_spawner.position)

func _spawn_initial_building(spawn_pos: Vector2):
	spawn_random_building(spawn_pos)

func spawn_random_building(spawn_pos: Vector2):
	var rand = randf()
	var scene_to_spawn: PackedScene
	
	if rand < 0.5 and georgian_houses.size() > 0:
		scene_to_spawn = georgian_houses[randi() % georgian_houses.size()]
	elif rand < 0.7 and shops.size() > 0:
		# Get a random shop that's different from the last one
		scene_to_spawn = get_different_shop()
	elif rand < 0.9 and modern_buildings.size() > 0:
		scene_to_spawn = modern_buildings[randi() % modern_buildings.size()]
	elif landmarks.size() > 0:
		scene_to_spawn = landmarks[randi() % landmarks.size()]
	
	if scene_to_spawn:
		# Remember if this was a shop
		if scene_to_spawn in shops:
			last_spawned_shop = scene_to_spawn
		else:
			last_spawned_shop = null
			
		spawn_element(scene_to_spawn, spawn_pos)

func get_different_shop() -> PackedScene:
	if shops.size() <= 1:
		return shops[0] if shops.size() > 0 else null
	
	var attempts = 0
	var chosen_shop: PackedScene
	
	# Try to get a different shop (max 5 attempts to avoid infinite loop)
	while attempts < 5:
		chosen_shop = shops[randi() % shops.size()]
		if chosen_shop != last_spawned_shop:
			return chosen_shop
		attempts += 1
	
	# If we can't find a different one, just return any shop
	return chosen_shop

func _spawn_street_element():
	if is_paused:
		return
	spawn_random_street_element(lamp_spawner.position)

func _spawn_initial_street_element(spawn_pos: Vector2):
	spawn_random_street_element(spawn_pos)

func spawn_random_street_element(spawn_pos: Vector2):
	var rand = randf()
	var scene_to_spawn: PackedScene
	
	if rand < 0.7 and lamp_posts.size() > 0:
		scene_to_spawn = lamp_posts[randi() % lamp_posts.size()]
	elif trees.size() > 0:
		scene_to_spawn = trees[randi() % trees.size()]
	
	if scene_to_spawn:
		spawn_element(scene_to_spawn, spawn_pos)

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

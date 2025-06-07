extends Node2D
class_name IslandGenerator

@export var map_size: int = 256
@export var noise_scale: float = 0.05
@export var island_size: float = 0.7
@export var falloff_strength: float = 3.0
@export var generate_on_ready: bool = true

# Saplings for GRASS biome
@export_group("Grass Biome Saplings")
@export var grass_sapling_scenes: Array[PackedScene] = []
@export var grass_sapling_chances: Array[float] = [] # All chances here, total spawn chance = sum

# Saplings for FOREST biome
@export_group("Forest Biome Saplings")
@export var forest_sapling_scenes: Array[PackedScene] = []
@export var forest_sapling_chances: Array[float] = [] # All chances here

# TileMap reference
@onready var tile_map: TileMapLayer = $TileMapLayer

# Noise generator
var noise: FastNoiseLite

# Store spawned trees for cleanup
var spawned_trees: Array[Node2D] = []

# Tile source IDs 
const DEEP_WATER = 6
const SHALLOW_WATER = 2
const BEACH = 4
const GRASS = 0
const FOREST = 1
const MOUNTAIN = 8

func _ready():
	setup_noise()
	if generate_on_ready:
		generate_island()

func setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale

func generate_island():
	if not tile_map:
		print("TileMap not found!")
		return
	
	tile_map.clear()
	clear_trees()
	
	for x in range(map_size):
		for y in range(map_size):
			var height = calculate_height(x, y)
			var tile_type = get_tile_type(height)
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(tile_type, 0))
			
			match tile_type:
				GRASS:
					spawn_sapling_for_biome(x, y, grass_sapling_scenes, grass_sapling_chances)
				FOREST:
					spawn_sapling_for_biome(x, y, forest_sapling_scenes, forest_sapling_chances)
				_:
					pass

func spawn_sapling_for_biome(tile_x: int, tile_y: int, scenes: Array[PackedScene], chances: Array[float]):
	if scenes.size() == 0 or chances.size() == 0:
		return
	
	var total_chance = 0.0
	for chance in chances:
		total_chance += chance
	
	if total_chance <= 0:
		return
	
	# First decide if we spawn any sapling at all on this tile
	if randf() > total_chance:
		return
	
	var r = randf() * total_chance
	var cumulative = 0.0
	for i in range(scenes.size()):
		cumulative += chances[i]
		if r <= cumulative:
			spawn_tree_at_tile(tile_x, tile_y, scenes[i])
			return

func spawn_tree_at_tile(tile_x: int, tile_y: int, tree_scene: PackedScene):
	if not tree_scene:
		return
	
	var tree = tree_scene.instantiate()
	var world_pos = tile_map.map_to_local(Vector2i(tile_x, tile_y))
	tree.position = world_pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	add_child(tree)
	spawned_trees.append(tree)

func clear_trees():
	for tree in spawned_trees:
		if is_instance_valid(tree):
			tree.queue_free()
	spawned_trees.clear()

func calculate_height(x: int, y: int) -> float:
	var noise_value = noise.get_noise_2d(x, y)
	var center_x = map_size / 2.0
	var center_y = map_size / 2.0
	var distance = sqrt((x - center_x) * (x - center_x) + (y - center_y) * (y - center_y))
	var max_distance = map_size * island_size / 3.0
	var falloff = 1.0
	if distance > max_distance:
		falloff = pow(1.0 - (distance - max_distance) / (map_size / 2.0 - max_distance), falloff_strength)
		falloff = max(0.0, falloff)
	var height = (noise_value + 1.0) / 2.0 * falloff
	return clamp(height, 0.0, 1.0)

func get_tile_type(height: float) -> int:
	if height < 0.1:
		return DEEP_WATER
	elif height < 0.2:
		return SHALLOW_WATER
	elif height < 0.25:
		return BEACH
	elif height < 0.5:
		return GRASS
	elif height < 0.6:
		return FOREST
	elif height < 0.8:
		return MOUNTAIN
	else:
		return MOUNTAIN

func regenerate():
	noise.seed = randi()
	generate_island()

func update_settings(new_map_size: float, new_noise_scale: float, new_island_size: float, new_falloff_strength: float):
	map_size = new_map_size
	noise_scale = new_noise_scale
	island_size = new_island_size
	falloff_strength = new_falloff_strength
	noise.frequency = noise_scale
	generate_island()

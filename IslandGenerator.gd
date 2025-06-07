@tool
extends Node2D
class_name IslandGenerator

@export var map_size: int = 256
@export var noise_scale: float = 0.05
@export var island_size: float = 0.7
@export var falloff_strength: float = 3.0
@export var generate_on_ready: bool = true

# TileMap reference
@onready var tile_map: TileMapLayer = $TileMapLayer

# Noise generator
var noise: FastNoiseLite

# Tile source IDs (you'll need to set these up in your TileSet)
const DEEP_WATER = 5
const SHALLOW_WATER = 2
const BEACH = 3
const GRASS = 0
const FOREST = 1
const MOUNTAIN = 4

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
	
	# Clear existing tiles
	tile_map.clear()
	
	# Generate height map and place tiles
	for x in range(map_size):
		for y in range(map_size):
			var height = calculate_height(x, y)
			var tile_type = get_tile_type(height)
			
			# Place tile at position
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(tile_type, 0))

func calculate_height(x: int, y: int) -> float:
	# Get noise value
	var noise_value = noise.get_noise_2d(x, y)
	
	# Calculate distance from center for radial falloff
	var center_x = map_size / 2.0
	var center_y = map_size / 2.0
	var distance = sqrt((x - center_x) * (x - center_x) + (y - center_y) * (y - center_y))
	var max_distance = map_size * island_size / 3.0
	
	# Apply radial falloff
	var falloff = 1.0
	if distance > max_distance:
		falloff = pow(1.0 - (distance - max_distance) / (map_size / 2.0 - max_distance), falloff_strength)
		falloff = max(0.0, falloff)
	
	# Combine noise and falloff
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

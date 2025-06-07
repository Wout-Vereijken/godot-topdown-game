@tool
extends Node2D
class_name IslandGenerator

@export var map_size: int = 256
@export var noise_scale: float = 0.00
@export var island_size: float = 0.7
@export var falloff_strength: float = 3.0
@export var generate_on_ready: bool = true

@onready var tile_map: TileMapLayer = $TileMapLayer

var noise: FastNoiseLite
var temp_noise: FastNoiseLite
var moisture_noise: FastNoiseLite

const GRASS = 0
const FOREST = 1
const SHALLOW_WATER = 2
const TUNDRA = 3
const BEACH = 4
const MOUNTAIN = 5
const DEEP_WATER = 6
const DESERT = 7
const ROCKY = 8
const DEEPER_WATER = 9
const SAVANNA = 10
const DRY_GRASSLAND = 11

# Struct for thresholds
class Thresholds:
	var temp_low = 0.0
	var temp_mid = 0.0
	var temp_high = 0.0
	var moist_low = 0.0
	var moist_mid = 0.0
	var moist_high = 0.0

func _ready():
	setup_noise()
	if generate_on_ready:
		generate_island()

func setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	
	temp_noise = FastNoiseLite.new()
	temp_noise.seed = randi()
	temp_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	temp_noise.frequency = 0.005
	
	moisture_noise = FastNoiseLite.new()
	moisture_noise.seed = randi()
	moisture_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	moisture_noise.frequency = 0.01

func fbm(x: float, y: float, octaves: int, lacunarity: float, gain: float) -> float:
	var amplitude = 1.0
	var frequency = 1.0
	var sum = 0.0
	for i in range(octaves):
		sum += amplitude * noise.get_noise_2d(x * frequency, y * frequency)
		frequency *= lacunarity
		amplitude *= gain
	return sum

func calculate_height(x: int, y: int) -> float:
	var n = fbm(float(x), float(y), 4, 2.0, 0.5)
	n = (n + 1.0) / 2.0  # Normalize to 0..1
	
	var center = map_size / 2.0
	var dist = Vector2(x - center, y - center).length()
	var dist_norm = dist / (map_size / 2.0)
	
	# Smooth island falloff with sigmoid
	var falloff = 1.0 / (1.0 + exp((dist_norm - island_size) * falloff_strength * 5.0))
	
	var height = n * falloff
	return clamp(height, 0.0, 1.0)

func calculate_temperature(x: int, y: int, height: float) -> float:
	# Latitude-based temp (north=0, south=1)
	var lat = float(y) / float(map_size)
	var lat_temp = 1.0 - abs(lat - 0.5) * 2.0  # 1.0 at equator, 0.0 at poles
	
	var noise_temp = (temp_noise.get_noise_2d(x, y) + 1.0) / 2.0
	
	# Blend noise with latitude, and reduce temp by height (colder at high altitude)
	var temperature = lat_temp * 0.7 + noise_temp * 0.3
	temperature *= 1.0 - height * 0.6
	
	return clamp(temperature, 0.0, 1.0)

func calculate_moisture(x: int, y: int) -> float:
	return clamp((moisture_noise.get_noise_2d(x, y) + 1.0) / 2.0, 0.0, 1.0)

func get_percentile(arr: Array, p: float) -> float:
	var index = int(p * float(arr.size() - 1))
	return arr[index]

func get_tile_type(height: float, temperature: float, moisture: float, thresholds: Thresholds) -> int:
	# Water
	if height < 0.05:
		return DEEPER_WATER
	elif height < 0.1:
		return DEEP_WATER
	elif height < 0.15:
		return SHALLOW_WATER
	elif height < 0.25:
		return BEACH
	
	# Lowlands (below 0.4)
	if height < 0.4:
		if moisture > thresholds.moist_high:
			return FOREST
			#increase the range for grass by lowering the threshold slightly
		elif moisture > thresholds.moist_mid:
			return GRASS
		else:
			return SAVANNA

	
	# Midlands (0.4 - 0.6)
	elif height < 0.6:
		if moisture > thresholds.moist_high:
			if temperature < thresholds.temp_mid:
				return TUNDRA
			else:
				return FOREST
		elif moisture > thresholds.moist_low:
			if temperature > thresholds.temp_high:
				return DESERT
			else:
				return DRY_GRASSLAND
		else:
			return DESERT
	
	# Highlands (0.6 - 0.75)
	elif height < 0.75:
		if moisture > thresholds.moist_mid:
			return ROCKY
		else:
			return DRY_GRASSLAND
	
	# Mountains (0.75+)
	else:
		if moisture > thresholds.moist_mid:
			return ROCKY
		else:
			return MOUNTAIN

func calculate_thresholds() -> Thresholds:
	var temp_values = []
	var moisture_values = []

	# Collect temp and moisture only on land (height >= 0.25)
	for x in range(map_size):
		for y in range(map_size):
			var height = calculate_height(x, y)
			if height >= 0.25:
				var temp = calculate_temperature(x, y, height)
				var moist = calculate_moisture(x, y)
				temp_values.append(temp)
				moisture_values.append(moist)

	temp_values.sort()
	moisture_values.sort()

	var thresholds = Thresholds.new()
	thresholds.temp_low = get_percentile(temp_values, 0.25)
	thresholds.temp_mid = get_percentile(temp_values, 0.5)
	thresholds.temp_high = get_percentile(temp_values, 0.85)

	thresholds.moist_low = get_percentile(moisture_values, 0.35)
	thresholds.moist_mid = get_percentile(moisture_values, 0.15)
	thresholds.moist_high = get_percentile(moisture_values, 0.85)


	return thresholds

func generate_island():
	if not tile_map:
		print("TileMap not found!")
		return
	tile_map.clear()

	# Calculate thresholds before generating tiles
	var thresholds = calculate_thresholds()

	for x in range(map_size):
		for y in range(map_size):
			var height = calculate_height(x, y)
			var temperature = calculate_temperature(x, y, height)
			var moisture = calculate_moisture(x, y)
			var tile_type = get_tile_type(height, temperature, moisture, thresholds)
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(tile_type, 0))

func regenerate():
	noise.seed = randi()
	temp_noise.seed = randi()
	moisture_noise.seed = randi()
	generate_island()

func update_settings(new_map_size: int, new_noise_scale: float, new_island_size: float, new_falloff_strength: float):
	map_size = new_map_size
	noise_scale = new_noise_scale
	island_size = new_island_size
	falloff_strength = new_falloff_strength
	noise.frequency = noise_scale
	temp_noise.frequency = 0.005
	moisture_noise.frequency = 0.01
	generate_island()

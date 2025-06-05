extends Control

@onready var island_generator: IslandGenerator = $"../../IslandGenerator"
@onready var size_slider: HSlider = $VBoxContainer/SizeContainer/SizeSlider
@onready var noise_scale_slider: HSlider = $VBoxContainer/NoiseScaleContainer/NoiseScaleSlider
@onready var island_size_slider: HSlider = $VBoxContainer/IslandSizeContainer/IslandSizeSlider
@onready var falloff_slider: HSlider = $VBoxContainer/FalloffContainer/FalloffSlider
@onready var generate_button: Button = $VBoxContainer/GenerateButton

@onready var noise_scale_label: Label = $VBoxContainer/NoiseScaleContainer/NoiseScaleLabel
@onready var island_size_label: Label = $VBoxContainer/IslandSizeContainer/IslandSizeLabel
@onready var falloff_label: Label = $VBoxContainer/FalloffContainer/FalloffLabel

func _ready():
	setup_ui()
	connect_signals()

func setup_ui():
	size_slider.min_value = 64
	size_slider.max_value = 1028
	size_slider.step = 64
	size_slider.value = island_generator.map_size
	
	noise_scale_slider.min_value = 0.01
	noise_scale_slider.max_value = 0.2
	noise_scale_slider.step = 0.01
	noise_scale_slider.value = island_generator.noise_scale
	
	island_size_slider.min_value = 0.3
	island_size_slider.max_value = 1.0
	island_size_slider.step = 0.1
	island_size_slider.value = island_generator.island_size
	
	falloff_slider.min_value = 1.0
	falloff_slider.max_value = 5.0
	falloff_slider.step = 0.1
	falloff_slider.value = island_generator.falloff_strength
	
	update_labels()

func connect_signals():
	size_slider.value_changed.connect(_on_size_slider_changed)
	noise_scale_slider.value_changed.connect(_on_noise_scale_changed)
	island_size_slider.value_changed.connect(_on_island_size_changed)
	falloff_slider.value_changed.connect(_on_falloff_changed)
	generate_button.pressed.connect(_on_generate_pressed)
	
func _on_size_slider_changed(value: float):
	island_generator.update_settings(
		int(value),
		noise_scale_slider.value,
		island_size_slider.value,
		falloff_slider.value
	)
	update_labels()

func _on_noise_scale_changed(value: float):
	island_generator.update_settings(
		int(size_slider.value),
		value,
		island_size_slider.value,
		falloff_slider.value
	)
	update_labels()

func _on_island_size_changed(value: float):
	island_generator.update_settings(
		int(size_slider.value),
		noise_scale_slider.value,
		value,
		falloff_slider.value
	)
	update_labels()

func _on_falloff_changed(value: float):
	island_generator.update_settings(
		int(size_slider.value),
		noise_scale_slider.value,
		island_size_slider.value,
		value
	)
	update_labels()

func _on_generate_pressed():
	island_generator.regenerate()

func update_labels():
	noise_scale_label.text = "Noise Scale: %.3f" % noise_scale_slider.value
	island_size_label.text = "Island Size: %.1f" % island_size_slider.value
	falloff_label.text = "Falloff Strength: %.1f" % falloff_slider.value

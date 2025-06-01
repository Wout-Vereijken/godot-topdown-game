extends Node2D

@onready var ground: TileMapLayer = $ground
@onready var preview: TileMapLayer = $preview


var preview_tile : Vector2i = Vector2i(-999, -999)  # Startwaarde buiten bereik

func get_snapped_position(global_pos: Vector2) -> Vector2i:
	var local_pos = ground.to_local(global_pos)
	return ground.local_to_map(local_pos)

func _physics_process(_delta: float) -> void:
	if Global.select_mode:
		var new_tile = get_snapped_position(get_global_mouse_position())
		# Alleen als de muis op een andere tegel is dan voorheen
		if new_tile != preview_tile:
			# Verwijder vorige preview
			preview.erase_cell(preview_tile)
			# Zet nieuwe preview
			preview.set_cell(new_tile, Global.source_id, Global.selected_tile)
			# Update de huidige preview_tile
			preview_tile = new_tile

func _input(event):
	if event.is_action_pressed("mouse_click_left") and event.pressed:
		if Global.select_mode:
			var tile_pos = get_snapped_position(get_global_mouse_position())
			place_tile(tile_pos)
			Global.select_mode = false

func place_tile(tile_pos: Vector2i):
	ground.set_cell(tile_pos, Global.source_id, Global.selected_tile)
	print("tile placed")

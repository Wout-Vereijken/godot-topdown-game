extends Control

func _on_button_pressed_forest_tree() -> void:
	Global.source_id = 0
	Global.selected_tile = Vector2i(1, 1)
	Global.select_mode = true
	print("tree button pressed")

func _on_button_pressed_forest_tree_dark() -> void:
	Global.source_id = 0
	Global.selected_tile = Vector2i(6, 1)
	Global.select_mode = true
	print("dark tree button pressed")

func _on_button_pressed_forest_tree_orange() -> void:
	Global.source_id = 0
	Global.selected_tile = Vector2i(2, 1)
	Global.select_mode = true
	print("orange tree button pressed")

extends Button

var buildingMenuState : bool = false
var scene = preload("res://ui/scenes/control.tscn")
var instance = scene.instantiate()

func _on_toggled(toggled_on: bool) -> void:
	var ui_root = get_tree().current_scene.get_node("CanvasLayer")  # Replace with your node's name/path

	if buildingMenuState == false:
		buildingMenuState = true
		ui_root.add_child(instance)
	elif buildingMenuState == true:
		ui_root.remove_child(instance)
		buildingMenuState = false

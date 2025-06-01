extends Camera2D

@export var zoom_speed := 0.1
@export var min_zoom := 0.5
@export var max_zoom := 2.0
@export var drag_active := false
@export var last_mouse_pos := Vector2()

func _unhandled_input(event):
	# Start pannen
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			drag_active = event.pressed
			if drag_active:
				last_mouse_pos = get_global_mouse_position()

	# Scroll zoom
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			adjust_zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			adjust_zoom(zoom_speed)

func _physics_process(_delta):
	if drag_active:
		var mouse_pos = get_global_mouse_position()
		var delta = last_mouse_pos - mouse_pos
		global_position += delta
		last_mouse_pos = mouse_pos

func adjust_zoom(amount):
	var new_zoom = zoom + Vector2(amount, amount)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	zoom = new_zoom

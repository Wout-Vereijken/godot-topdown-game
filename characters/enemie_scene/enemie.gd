extends CharacterBody2D

@export var target: Node2D

@export var speed = 100
@export var acceleration = 7

@onready var navigationAgent: NavigationAgent2D = $navigation/NavigationAgent2D

func _physics_process(delta: float):
	var direction = Vector2.ZERO
	direction = navigationAgent.get_next_path_position() - global_position
	direction = direction.normalized()
	
	velocity = velocity.lerp(direction * speed, acceleration * delta)
	
	move_and_slide()



func _on_timer_timeout() -> void:
	navigationAgent.target_position = target.global_position
	

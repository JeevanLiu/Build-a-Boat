extends StaticBody3D

@export var health = 2

func _process(delta: float) -> void:
	if health <= 0:
		queue_free()

func damage():
	health -= 1

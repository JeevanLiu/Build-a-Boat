extends RigidBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if position.y < -150:
		queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Ship"):
		for block in body.get_children():
			if abs(block.global_position - self.global_position) < Vector3(0.1, 0.1, 0.1):
				block.acidHit()
	elif body.is_in_group("player"):
		body.damage(10)
	queue_free()
	

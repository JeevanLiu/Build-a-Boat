extends RigidBody3D

var speed = 50
var direction

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.global_position += direction * speed * delta

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Blocks"):
		body.evilCannonHit()
	queue_free()

func setTarget(initialTarget: Vector3):
	direction = (initialTarget - global_position).normalized()

extends StaticBody3D

@export var health = 2.0
@export var maxHealth = 2.0

func _process(delta: float) -> void:
	if health <= 0:
		queue_free()

func damage(amount):
	health -= amount
	changeSize()

func changeSize():
	var scaling = (health + 5) / (maxHealth + 5)
	$CollisionShape3D.scale *= scaling
	$MeshInstance3D.scale *= scaling
	self.position.y *= scaling

extends StaticBody3D

# Cannon projectile
var cannonProj = preload("res://Scenes/Water_Areas/Objects/cannon_projectile.tscn")

# Ballista arrow
var ballistaProj = preload("res://Scenes/Water_Areas/Objects/ballista_arrow.tscn")

var projectile = cannonProj # As a failsafe base

# Shooting mechanism important variables
var fireTimer = true
var bodyList = []
var parentDirection = 0 # To get cannons after corners working
var rightOffset = Vector3(0, 0, -1)
var leftOffset = Vector3(0, 0, 1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if self.get_parent().get_parent().direction == -1:
		leftOffset = Vector3(1, 0, 0)
		rightOffset = Vector3(-1, 0, 0)
	elif self.get_parent().get_parent().direction == 1:
		leftOffset = Vector3(-1, 0, 0)
		rightOffset = Vector3(1, 0, 0)
	
	if self.name == "Ballista":
		projectile = ballistaProj


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !bodyList.is_empty():
		if fireTimer:
			fireTimer = false
			var idealBody = bodyList.pick_random()
			fireProjectile(idealBody.global_position + Vector3(randi_range(-5, 5), 0, randi_range(-5, 5))) # Makes the target the body position, adding some random variance
			await get_tree().create_timer(3).timeout
			fireTimer = true


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Blocks") or body.is_in_group("player"):
		bodyList.append(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Blocks") or body.is_in_group("player"):
		bodyList.erase(body)


func fireProjectile(target: Vector3):
	var proj = projectile.instantiate()
	
	var offset
	if is_equal_approx(self.rotation.y, PI / 2):
		offset = rightOffset
	else:
		offset = leftOffset
	
	if self.name == "Ballista":
		offset *= 2
	
	get_parent().add_child(proj)
	proj.global_position = self.global_position + offset
	proj.setTarget(target)

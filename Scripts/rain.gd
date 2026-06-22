extends MeshInstance3D

# Player (spawns when the player is near)
@onready var player = null

# Raindrops
var acidDroplet = preload("res://Scenes/Water_Areas/Objects/acid_drop.tscn")

# Cloud details
@onready var l = mesh.get_aabb().size.x - 2
@onready var w = mesh.get_aabb().size.z - 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player:
		if player in $"../Area3D".get_overlapping_bodies():
			rain()

func rain():
	var newDrop = acidDroplet.instantiate()
	# Sets up the position of the newLilRock
	newDrop.position = Vector3(randi_range(-l, l), 0, randi_range(-w, w))
	
	# Makes newLilRock a child of the scene
	add_child(newDrop)

func _on_area_3d_body_entered(body: Node3D) -> void:
	# Function determining if the player is nearby (body has a large radius around the cloud)
	if body.is_in_group("player"):
		player = body

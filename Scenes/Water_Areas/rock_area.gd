extends Area3D

@export var health = 2
@onready var dying = false

var contactList = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	for body in contactList:
		body.hitObject()
		damage()
	if health <= 0:
		for body in contactList:
			body.exitObject()
		get_parent().queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Blocks"):
		contactList.append(body)
		body.hitObject()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Blocks"):
		contactList.erase(body)
		body.exitObject()

func damage():
	health -= 1

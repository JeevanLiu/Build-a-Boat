extends Area3D

@export var health = 2
@onready var dying = false

var contactList = []
var damage_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	damage_timer = Timer.new()
	damage_timer.wait_time = 0.25    # Damage timer
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Blocks"):
		contactList.append(body)
		body.hitObject()
		if contactList.size() == 1:
			damage_timer.start()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Blocks"):
		contactList.erase(body)
		body.exitObject()
		if contactList.is_empty():
			damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	for body in contactList:
		body.hitObject()
		damage()
		if health <= 0:
			get_parent().queue_free()
		body.exitObject()

func damage():
	health -= 1

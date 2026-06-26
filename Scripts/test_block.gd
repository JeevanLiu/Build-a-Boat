extends CollisionShape3D

# Health - Hits the object can take
# Endurance - Makes the block sturdier (in case I wanna have upgrades of sorts or health restore stuff)
# Luck - Chance to not take damage (maybe create fun blocks with high luck but can only take 1 hit if unlucky)
@export var health = 5.0
@export var maxHealth = 5.0
@export var endurance = 1.0
@export var luck = 1

# Other stats
@export var acidEndurance = 1.0

# Parent
@onready var ship = $".."
@onready var player = get_node("/root/World1/Player")

@onready var damageTouching = []
@onready var inWater = false

# Area Specific Variables
@onready var poisoned = false

# Block Specific Variables

# Chair/Sitting
@onready var sitting = false

# Healing timer
@onready var healable = true

# preview mode for before placing
var previewMode = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if (previewMode):
		self.set_deferred("disabled", true) # no collision in preview
		
		var holoMaterial = ShaderMaterial.new()
		holoMaterial.shader = load("res://Scripts/Shaders/hologram.gdshader")
		$MeshInstance3D.set_surface_override_material(0, holoMaterial)
		
		'''var mat : Material = $MeshInstance3D.get_active_material(0)
		mat.transparency = 1
		mat.albedo_color.a = 0.5
		mat.next_pass = ShaderMaterial.new()
		mat.next_pass.shader = load("res://Scripts/Shaders/hologram.gdshader")'''


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	# Block damage logic
	var touching = $DamageArea.get_overlapping_bodies()
	for obj in touching:
		if obj.is_in_group("Rocks"):
			obj.damage(1)
			self.damage(1)
		elif obj.is_in_group("hasPoison"):
			poisonTick()
	
	# Handles sitting related events
	if abs(player.global_position - self.global_position) < Vector3(3, 3, 3) and Input.is_action_just_pressed("right_click"):
		# Calls sitting when near chairs
		if self.is_in_group("Sittable"):
			sit()
	
	elif Input.is_action_just_pressed("ui_accept"):
		sitting = false
	
	# Handles Chair events
	if self.is_in_group("Sittable"):
		if sitting:
			player.rotation = self.rotation
			
			var normOffset = Vector3(0, 2, 0)
			
			var rotatedOffset = self.global_transform.basis * normOffset
			
			player.global_position = self.global_position + rotatedOffset


# Taking acid rain damage
func acidHit():
	if randf_range(0, 100) > luck:
		print("Acid hit! health before = ", health)
		damage(2 / acidEndurance)
		print("Acid hit! health after = ", health)

func dies():
	if health <= 0:
		if self.is_in_group("Explodes"):
			explode()
		queue_free()

# Poison functions REWORK POISON I GOT RID OF THE THING THAT MAKES IT WORK EARLIER
func enterPoison():
	poisoned = true
func exitPoison():
	poisoned = false
func poisonTick():
	if randf_range(0, 100) > luck:
			health *= (1 - (0.0025 / acidEndurance))
func evilCannonHit():
	damage(4)

# Block Specific Functions

func _on_body_exited(body):
	# 
	if body == player:
		player = null
		if self.is_in_group("Sittable"):
			sitting = false

# Chair Sitting Function
func sit():
	sitting = !sitting
	if sitting:
		player.set_collision_layer_value(2, true)
		player.set_collision_layer_value(1, false)
	else:
		player.set_collision_layer_value(1, true)
		player.set_collision_layer_value(2, false)

# Explosion Function
func explode():
	# Damage
	var bodies = $BlastRadius.get_overlapping_bodies()
	for sibling in ship.get_children():
		if abs(sibling.position - self.position) < Vector3(3, 3, 3):
			sibling.damage(2)
	if abs(player.global_position - self.global_position) < Vector3(3, 3, 3):
		player.damage(15)
	for body in bodies:
		if body.is_in_group("Rocks"):
			body.damage(5)
	
	# Impulse effect
	var epic = self.global_position - ship.global_position
	var epic2 = epic.normalized()
	ship.apply_impulse(epic2, self.global_position)
	print("Applied " + str(epic2) + " in the direction" + str(epic))

func damage(amount):
	# Luck logic:
	if randf_range(0, 100) > luck:
		health -= (amount / endurance)
	if self.health <= 0:
		dies()
	elif self.health >= 250:
		self.health = 250 # Maximum health capped at 250 for healing blocks


func _on_damage_area_body_entered(body: Node3D) -> void:
	if Globals.launched:
		if self.is_in_group("LifeSteal"):
			if self.health < 5 and player.health >= 10:
				player.damage(5)
				self.health += 10
				self.endurance += 0.5
				self.acidEndurance += 0.25
		elif self.is_in_group("Heal"):
			if healable:
				healable = false
				player.health += 5
				player.updateHealth()
				$HealTimer.start()
				await $HealTimer.timeout
				healable = true

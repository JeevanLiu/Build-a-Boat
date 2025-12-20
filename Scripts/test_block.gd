extends RigidBody3D

# Health - Hits the object can take
# Endurance - Makes the block sturdier (in case I wanna have upgrades of sorts or health restore stuff)
# Luck - Chance to not take damage (maybe create fun blocks with high luck but can only take 1 hit if unlucky)
@export var health = 5.0
@export var endurance = 1.0
@export var luck = 1

@onready var hit = false
@onready var inWater = false
@onready var touchWater = 0
@onready var direction = 0
@onready var waterFlowVelNorm = Vector3(6.0, 0.0, 0.0)
@onready var waterFlowVelRight = Vector3(0.0, 0.0, 6.0)
@onready var waterFlowVelLeft = Vector3(0.0, 0.0, -6.0)

# Area Specific Variables
@onready var poisoned = false

# Block Specific Variables

# Chair/Sitting
@onready var sitting = false
@onready var player = null

# preview mode for before placing
var previewMode = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if (previewMode):
		$CollisionShape3D.queue_free() # no collision in preview
		
		var holoMaterial = ShaderMaterial.new()
		holoMaterial.shader = load("res://Scripts/Shaders/hologram.gdshader")
		$MeshInstance3D.set_surface_override_material(0, holoMaterial)
		
		'''var mat : Material = $MeshInstance3D.get_active_material(0)
		mat.transparency = 1
		mat.albedo_color.a = 0.5
		mat.next_pass = ShaderMaterial.new()
		mat.next_pass.shader = load("res://Scripts/Shaders/hologram.gdshader")'''
	
	# Connecting Chair Functions
	if self.is_in_group("Sittable"):
		$ChairArea.body_entered.connect(_on_body_entered)
		$ChairArea.body_exited.connect(_on_body_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Kill the block when it dies
	dies()
		
	# Water touching logic
	if inWater:
		if direction == 0: # Forward
			linear_velocity = waterFlowVelNorm
		elif direction == -2: # Left
			linear_velocity = waterFlowVelLeft
		elif direction == 2: # Right
			linear_velocity = waterFlowVelRight
		elif direction == -1:
			linear_velocity = waterFlowVelNorm + waterFlowVelLeft
		elif direction == 1:
			linear_velocity = waterFlowVelNorm + waterFlowVelRight
	
	# Block touching logic
	if hit:
		# Luck logic:
		if randf_range(0, 100) > luck:
			health -= (1.0 / endurance)
			print("Damage taken, new health = ", health)
		else:
			print("Lucky break")
	
	# Poison logic
	if int(delta) % 60 == 0:
		if poisoned:
			poisonTick()
	
	# Handles sitting related events
	if player and Input.is_action_just_pressed("right_click"):
		# Calls sitting when near chairs
		if self.is_in_group("Sittable"):
			sit()
	
	elif player and Input.is_action_just_pressed("ui_accept"):
		sitting = false
	
	# Handles Chair events
	if self.is_in_group("Sittable"):
		if sitting and player:
			player.global_position = self.global_position + Vector3(0, 1.25, 0)

# Interact with water function
func enterWater():
	touchWater += 1
	inWater = true
func exitWater():
	touchWater -= 1
	if touchWater <= 0:
		inWater = false
		linear_velocity = Vector3.ZERO

# Hitting a damaging object function
func hitObject():
	hit = true
	print("Hit: Health before = ", health)
func exitObject():
	hit = false

# Taking acid rain damage
func acidHit():
	if randf_range(0, 100) > luck:
		print("Acid hit! health before = ", health)
		health -= 1
		print("Acid hit! health after = ", health)

func dies():
	if health <= 0:
		queue_free()

# Poison functions
func enterPoison():
	poisoned = true
func exitPoison():
	poisoned = false
func poisonTick():
	if randf_range(0, 100) > luck:
			health /= 1.0025
			print("Poisoned, new health = ", health)
func evilCannonHit():
	if randf_range(0, 100) > luck:
		health -= (4.0 / endurance)
		print("evil cannon hit!", health)

# Fast area functions
func changeSpeed():
	if waterFlowVelNorm == Vector3(6.0, 0.0, 0.0):
		waterFlowVelNorm = Vector3(30.0, 0.0, 0.0)
		waterFlowVelLeft = Vector3(0.0, 0.0, -30.0)
		waterFlowVelRight = Vector3(0.0, 0.0, 30.0)
	else:
		waterFlowVelNorm = Vector3(6.0, 0.0, 0.0)
		waterFlowVelRight = Vector3(0.0, 0.0, 6.0)
		waterFlowVelLeft = Vector3(0.0, 0.0, -6.0)

# Block Specific Functions

func _on_body_entered(body):
	# Function determining if the player is nearby (body has a large radius around the block)
	if body.is_in_group("player"):
		player = body

func _on_body_exited(body):
	# 
	if body == player:
		player = null
		if self.is_in_group("Sittable"):
			sitting = false

# Chair Sitting Function
func sit():
	sitting = !sitting

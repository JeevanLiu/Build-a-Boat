extends RigidBody3D

@onready var hit = false
@onready var inWater = true
@onready var touchWater = 0
@onready var direction = 0
@onready var waterFlowVel = 6
@onready var waterFlowMax = 6
@onready var incline = false
@onready var inclineBoost = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	# Water touching logic
	if Globals.launched and inWater:
		if direction == 0: # Forward
			linear_velocity.x += waterFlowVel
		elif direction == -2: # Left
			linear_velocity.z -= waterFlowVel
		elif direction == 2: # Right
			linear_velocity.z += waterFlowVel
		elif direction == -1: # Diagonally Left
			linear_velocity.x += waterFlowVel
			linear_velocity.z -= waterFlowVel
		elif direction == 1: # Diagonally Right
			linear_velocity.x += waterFlowVel
			linear_velocity.z += waterFlowVel
		if linear_velocity.x > waterFlowMax:
			linear_velocity.x = waterFlowMax
		if abs(linear_velocity.z) > waterFlowMax:
			if direction < 0:
				linear_velocity.z = -waterFlowMax
			else:
				linear_velocity.z = waterFlowMax
	
	if on_floor():
		linear_velocity.y = 0
	else:
		linear_velocity += get_gravity() * delta
	
	if incline:
		linear_velocity.y = inclineBoost
	
	print("ship linear velocity = ", linear_velocity)

# Interact with water function
func enterWater():
	touchWater += 1
	inWater = true
	print("touched water! new value = ", touchWater)
func exitWater():
	touchWater -= 1
	print("exited water! new value = ", touchWater)
	if touchWater <= 0:
		inWater = false
		print("EXITING WATER COMPLETELY")

# Fast area functions
func changeSpeed(area: bool): # True = fastArea, false = crazyArea
	if area:
		if waterFlowMax == 30:
			waterFlowMax = 6
		else:
			waterFlowMax = 30
	else:
		if waterFlowMax == 12.5:
			waterFlowMax = 6
		else:
			waterFlowMax = 12.5

func on_floor():
	return abs(linear_velocity.y) < 0.1

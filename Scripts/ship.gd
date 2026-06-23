extends RigidBody3D

@onready var hit = false
@onready var inWater = true
@onready var touchWater = 0
@onready var direction = 0
@onready var waterFlowVel = 6
@onready var waterFlowMax = 6
@onready var incline = false
@onready var inclineBoost = Vector3(0, 1.5, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	# Updates mass and inertia dynamically
	var childCount = get_child_count()
	var childLog = log(childCount)
	if childLog > 1:
		mass = childLog
		inertia = Vector3(childLog, childLog, childLog)
	
	# Water touching logic
	if Globals.launched and inWater:
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
		#linear_velocity.y = inclineBoost
		apply_central_force(inclineBoost)
	
	#print("ship linear velocity = ", linear_velocity) # Debugging velocity issues

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
		set_constant_force(Vector3.ZERO)

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

# Movement adjustment
func move():
	var massAssist = max(1, mass / 2)
	if direction == 0: # Forward
		set_constant_force(massAssist * Vector3(100, 0, 0))
	elif direction == -2: # Left
		set_constant_force(massAssist * Vector3(0, 0, -100))
	elif direction == 2: # Right
		set_constant_force(massAssist * Vector3(0, 0, 100))
	elif direction == -1: # Diagonally Left
		set_constant_force(massAssist * Vector3(75, 0, -75))
	elif direction == 1: # Diagonally Right
		set_constant_force(massAssist * Vector3(75, 0, 75))

func turn(newDir):
	direction = newDir
	move()

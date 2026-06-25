extends RigidBody3D

@onready var hit = false
@onready var touchWater = 0
@onready var direction = 0
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
		inertia = Vector3(childCount, childCount, childCount)
	
	# Water touching logic
	
	if linear_velocity.x > waterFlowMax:
		linear_velocity.x = waterFlowMax
	if abs(linear_velocity.z) > waterFlowMax:
		if direction < 0:
			linear_velocity.z = -waterFlowMax
		else:
			linear_velocity.z = waterFlowMax
	
	if touchWater > 1 and is_equal_approx(self.linear_velocity.x, 0) and is_equal_approx(self.linear_velocity.y, 0) and is_equal_approx(self.linear_velocity.z, 0):
		print("Almost 0!")
		self.linear_velocity.y = 20
	
	apply_central_force(get_gravity() * mass * delta)
	
	if incline:
		apply_central_force(inclineBoost)
	
	#print("ship linear velocity = ", linear_velocity) # Debugging velocity issues

# Interact with water function
func enterWater():
	touchWater += 1
	print("touched water! new value = ", touchWater)
func exitWater():
	touchWater -= 1
	print("exited water! new value = ", touchWater)
	if touchWater <= 0:
		print("EXITING WATER COMPLETELY")
		set_constant_force(Vector3.ZERO)

# Fast area functions
func changeSpeed(area: bool, up: bool): # True = fastArea, false = crazyArea -- True = speed up, false = slow down
	var change
	if up:
		change = 1
	else:
		change = -1
	
	if area:
		waterFlowMax += change * 30
	else:
		waterFlowMax += change * 12.5
	print("New max velocity:" + str(waterFlowMax))

func on_floor():
	return abs(linear_velocity.y) < 0.1

# Movement adjustment
func move():
	var massAssist = max(1, mass * 0.75)
	var buoyancy = get_gravity() * mass * 2
	if direction == 0: # Forward
		apply_central_force(massAssist * Vector3(400, buoyancy.y, 0))
		#print("Applying force in the direction: " + str(direction))
	elif direction == -2: # Left
		apply_central_force(massAssist * Vector3(0, buoyancy.y, -400))
	elif direction == 2: # Right
		apply_central_force(massAssist * Vector3(0, buoyancy.y, 400))
		#print("Applying force in the direction: " + str(direction))
	elif direction == -1: # Diagonally Left
		apply_central_force(massAssist * Vector3(400, buoyancy.y, -400))
	elif direction == 1: # Diagonally Right
		apply_central_force(massAssist * Vector3(400, buoyancy.y, 400))

func turn(newDir):
	direction = newDir
	move()

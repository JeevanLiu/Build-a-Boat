extends RigidBody3D

@onready var hit = false
@onready var touchWater = 0
@onready var direction = 0
@onready var waterFlowMax = 6
@onready var incline = false
@onready var inclineBoost = Vector3(0, 1.5, 0)

@onready var specialCase = false

@onready var shipScript = load("res://Scripts/ship.gd")

@onready var histChildCount = self.get_child_count()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#self.set_script(shipScript)
	#self.add_to_group("Ship")

	print("I was just born")

func _process(delta: float) -> void:
	var newChildCount = self.get_child_count()
	if newChildCount != histChildCount:
		self.reevaluateParts(self)
	histChildCount = newChildCount


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	# Updates mass and inertia dynamically
	var childCount = get_child_count()
	var childLog = log(childCount)
	if childLog > 1:
		mass = childLog
		inertia = Vector3(childCount, childCount, childCount)
	
	# Water touching logic
	
	if linear_velocity.x > waterFlowMax and !specialCase:
		linear_velocity.x = waterFlowMax
	if abs(linear_velocity.z) > waterFlowMax and !specialCase:
		if direction < 0:
			linear_velocity.z = -waterFlowMax
		else:
			linear_velocity.z = waterFlowMax
	
	if touchWater > 1 and !self.freeze and is_equal_approx(self.linear_velocity.x, 0) and is_equal_approx(self.linear_velocity.y, 0) and is_equal_approx(self.linear_velocity.z, 0):
		print("Almost 0!")
		self.linear_velocity.y = 20
	
	apply_central_force(get_gravity() * mass * delta)
	
	if incline:
		apply_central_force(inclineBoost)
	
	#print("ship linear velocity = ", linear_velocity) # Debugging velocity issues
	
	# Forces that oppose motion
	if self.angular_velocity.x > 2:
		self.angular_velocity.x = 2
	elif self.angular_velocity.x < -2:
		self.angular_velocity.x = -2
	if self.angular_velocity.y > 2:
		self.angular_velocity.y = 2
	elif self.angular_velocity.y < -2:
		self.angular_velocity.y = -2
	if self.angular_velocity.z > 2:
		self.angular_velocity.z = 2
	elif self.angular_velocity.z < -2:
		self.angular_velocity.z = -2
	
	self.angular_damp = self.mass * 50
	#print("Ship angular velocity: " + str(self.angular_velocity))

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

func reevaluateParts(deadGuy):
	# Get all remaining blocks (excluding dead one)
	var remaining = []
	for child in self.get_children():
		if child != deadGuy:
			remaining.append(child)

	# Keep finding connected groups until no blocks left
	while remaining.size() > 0:
		var newShip = self.duplicate()
		for child in newShip.get_children():
			child.queue_free()
		get_parent().add_child(newShip)

		# Start a new group from the first remaining block
		var group = [remaining[0]]
		remaining.erase(remaining[0])

		# Flood fill - find all blocks connected to this group
		var i = 0
		while i < group.size():
			var current = group[i]

			# Check all remaining blocks for adjacency
			var j = remaining.size() - 1
			while j >= 0:  # Iterate backwards so we can remove safely
				var other = remaining[j]
				var dist = (current.global_position - other.global_position).length()
				if dist < 1.75:  # Adjust this to match your block size!
					group.append(other)
					remaining.erase(other)
				j -= 1
			i += 1

		# Add all blocks in this group to the new ship
		for block in group:
			block.reparent(newShip)
			print("REPARENTED")
	# FINAL GROUP OF BLOCKS KEEPS CURRENT PARENT
	print("Remaining children count:" + str(get_child_count()))

func turn(newDir):
	direction = newDir
	if !self.freeze:
		move()

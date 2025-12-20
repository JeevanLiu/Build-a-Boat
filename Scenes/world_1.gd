extends Node3D

# Water Areas
var basicAreaScene = preload("res://Scenes/Water_Areas/basic_area.tscn")
var longAreaScene = preload("res://Scenes/Water_Areas/long_area.tscn")
var poisonAreaScene = preload("res://Scenes/Water_Areas/poison_area.tscn")
var dropAreaScene = preload("res://Scenes/Water_Areas/drop_area.tscn")
var inclineAreaScene = preload("res://Scenes/Water_Areas/incline_area.tscn")
var acidRainAreaScene = preload("res://Scenes/Water_Areas/acid_rain_area.tscn")
var cornerAreaScene = preload("res://Scenes/Water_Areas/corner_area.tscn")
var fastAreaScene = preload("res://Scenes/Water_Areas/fast_area.tscn")
var evilCannonAreaScene = preload("res://Scenes/Water_Areas/cannon_area.tscn")
var tidalAreaScene = preload("res://Scenes/Water_Areas/tidal_area.tscn")
# Handled separately
var endingAreaScene = preload("res://Scenes/Water_Areas/ending_area.tscn")

# Functions for calling each scene
@onready var possibleAreas = [basicAreaScene, longAreaScene, poisonAreaScene, dropAreaScene, inclineAreaScene, acidRainAreaScene, cornerAreaScene, fastAreaScene, evilCannonAreaScene, tidalAreaScene]
#    
#    

# Types of blocks
@onready var block = preload("res://Scenes/Blocks/block.tscn")
@onready var stoneBlock = preload("res://Scenes/Blocks/stone_block.tscn")
@onready var luckyBlock = preload("res://Scenes/Blocks/lucky_block.tscn")
@onready var obsidian = preload("res://Scenes/Blocks/obsidian.tscn")
@onready var chair = preload("res://Scenes/Blocks/basic_chair.tscn")

# Dev Block (maybe fun gamemode later)
@onready var infinityBlock = preload("res://Scenes/Blocks/infinity_block.tscn")
@onready var infinityChair = preload("res://Scenes/Blocks/infinity_chair.tscn")

@onready var numAreas = 5 # Change to make more areas spawn
@onready var areaList = [] # List of procedurally generated areas
@onready var totalSpaceX = 0 # Displacement between areas on the X
@onready var totalSpaceY = 0 # Displacement between areas on the Y
@onready var totalSpaceZ = 0 # Displacement between areas on the Z
@onready var direction = 0 # 0 = forward, -1 = left, 1 = right
@onready var nextArea = 1 # Ensures the first level is a basic level

@onready var launched = false

@onready var player = $Player
@onready var blockZone = $BlockPlacementZone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(numAreas):
		var nextArea = possibleAreas.pick_random()
		loadArea(nextArea)
	
	loadArea(endingAreaScene)
	
	# connect player signals
	player.placeBlock.connect(placeBlock)
	player.previewBlock.connect(previewBlock)
	player.unpreviewBlock.connect(unpreviewBlock)
	player.scrollBlock.connect(scrollBlock)

func placeBlock(location : Vector3, id : String):
	blockZone.placeBlock(location, id)

func previewBlock(location : Vector3, id : String):
	blockZone.previewBlock(location, id)

func unpreviewBlock():
	blockZone.deletePreviewBlock()

func scrollBlock(up: bool):
	blockZone.scrollBlock(up)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Handle Inputs
func _input(event):
	if Input.is_action_just_pressed("Launch"):
		if !launched:
			launched = true
			$LaunchAnimation.play("Launch")
			
			# Unfreezes blocks when the water shows up
			await get_tree().create_timer(0.5).timeout
			connectBlocks()
		

func loadArea(areaType: PackedScene):
	# Sets up newArea
	var newArea = areaType.instantiate()
	
	# Adds newArea to the areaList
	areaList.append(newArea)
	
	# Sets up the position of the newArea
	var areaSpacingX = 0
	var additionalY = 0
	var areaSpacingZ = 0
	var areaSpacing = 0
	var rotationError = 0
	
	# For normally rotated (non-inclines)
	if newArea.rotation.z == 0:
		areaSpacing = newArea.get_node("Water").get_node("MeshInstance3D").mesh.get_aabb().size.x
	# For rotated areas (inclines)
	else:
		var rotation = newArea.rotation.z
		var hypotenuse = newArea.get_node("Water").get_node("MeshInstance3D").mesh.get_aabb().size.x
		areaSpacing =  (cos(rotation)) * hypotenuse
		totalSpaceY += (sin(rotation)) * hypotenuse
		additionalY = - ((sin(rotation)) * hypotenuse) / 2
	var lengthZ = newArea.get_node("Water").get_node("MeshInstance3D").mesh.get_aabb().size.z
	rotationError = (areaSpacing - lengthZ) / 2
	
	# Transforms in either x or z:
	if direction == 0:
		areaSpacingX += (areaSpacing / 2) + 25 + totalSpaceX
		totalSpaceX += areaSpacing
		areaSpacingZ = totalSpaceZ
	elif direction == 1:
		areaSpacingX += ((areaSpacing / 2) + 25 + totalSpaceX - rotationError)
		newArea.rotation.y = - (PI / 2)
		areaSpacingZ += (totalSpaceZ + 25) + (areaSpacing / 2)
		totalSpaceZ += areaSpacing
	elif direction == -1:
		areaSpacingX += ((areaSpacing / 2) + 25 + totalSpaceX - rotationError)
		newArea.rotation.y = (PI / 2)
		areaSpacingZ += (totalSpaceZ - 25) - (areaSpacing / 2) 
		totalSpaceZ -= areaSpacing
	
	# For areas with a drop
	if newArea.get_node("BackWall") and !newArea.get_node("FrontWall"):
		totalSpaceY -= newArea.get_node("BackWall").get_node("MeshInstance3D").mesh.get_aabb().size.y
	
	# Finally sets the position and updates the space for the next area
	newArea.position = Vector3(areaSpacingX, totalSpaceY + additionalY, areaSpacingZ)
	
	# Changes direction if it is a corner:
	if newArea.is_in_group("Corner"):
		if direction == 1: # Current direction is already right
			newArea.rotation.y = PI
			totalSpaceX += areaSpacing
			direction = 0
		elif direction == -1: # Current direction is already left
			newArea.rotation.y = PI / 2
			totalSpaceX += areaSpacing
			direction = 0
		elif direction == 0: # Current direction is already forward
			totalSpaceX -= areaSpacing
			newArea.rotation.y = [0, - PI / 2].pick_random()
			if newArea.rotation.y == 0: # Turning right
				direction = 1
			else:  # Turning left
				direction = -1
	
	# Makes newArea a child of the scene
	add_child(newArea)

func connectBlocks():
	var blockList = []
	for block in get_children():
		if block is RigidBody3D:
			blockList.append(block)
			block.freeze = false
	for blockA in blockList:
		for blockB in blockList:
			if abs(blockB.global_position - blockA.global_position) <= Vector3(1, 1, 1): 
				var joint = Generic6DOFJoint3D.new()
				add_child(joint)
				joint.node_a = blockA.get_path()
				joint.node_b = blockB.get_path()
				
				joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
				joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
				joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
				
				joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
				joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
				joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
				joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
				joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
				joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
				
				joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
				joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
				joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
				joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 0.0)
				joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 0.0)
				joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 0.0)
				joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 0.0)
				joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 0.0)
				joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 0.0)
				


func _on_water_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Blocks"):
		body.enterWater()

func _on_water_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Blocks"):
		body.exitWater()

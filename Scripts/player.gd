extends CharacterBody3D

@export var placeBlockDistance = 2
@onready var sprint = 1
@onready var CamRotation : Vector2 = Vector2(0.0, 0.0)
@onready var sensitivity = 0.01
@onready var inWater = false
@onready var touchWater = 0
@onready var hit = false

@onready var direction = 0
@onready var waterSpeed = 1

# Player specific count variables
@onready var blockCountList = []
# Decrement during placement, read off of a file or something, OR DATABASE, add when gachad/bought
# But yeah base is 55 for now, 0 later... added in getPlayerBlocks()
@onready var money = 1000
# LATER - Start with 100 or so, enough for baby gacha, then yeh
@onready var health = 100
@onready var maxHealth = 100

# UI Variables
@onready var blocks = []

# Going down the list...
@onready var camera = $Camera
@onready var bpz = $"../BlockPlacementZone"
@onready var cblockDis = $"StatDisplay/Current Block"
@onready var moneyDis = $"StatDisplay/Current Money"
@onready var healthDis = $"StatDisplay/Current Health"
@onready var cameraDist = $Camera/SpringArm3D
@onready var settings = $Settings
@onready var abilities = $Abilities

# Area Specific Variables
@onready var poisoned = false

const SPEED = 5.0
const JUMP_VELOCITY = 10

# block placement
signal placeBlock
signal previewBlock
signal unpreviewBlock
signal scrollBlock

var mousePos : Vector2

# Handle Inputs
func _input(event):
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Handles sprinting
	if Input.is_action_just_pressed("sprint"):
		sprint = 3
	if Input.is_action_just_released("sprint"):
		sprint = 1
	# Settings open on esc
	if Input.is_action_just_pressed("ui_text_clear_carets_and_selection"):
		settings.changeMenu()
	
	# Abilities
	if Input.is_action_just_pressed("numbers"):
		var num = event.as_text().to_int() - 1
		if num == -1:
			num = 9
		abilities.abilityList[num].call()
	
	# Handles the camera... Thank you Jus
	if (event is InputEventMouseMotion):
		mousePos = event.position # save the mouse pos
		if (Input.is_action_pressed("left_click")):
			CamRotation += event.relative * sensitivity
			CamRotation.y = clamp(CamRotation.y, -1.5, 1.5)
			camera.transform.basis = Basis()
			# rot cam on x
			camera.rotate_object_local(Vector3(0,1,0),-CamRotation.x)
			# rot cam on y
			camera.rotate_object_local(Vector3(1,0,0),-CamRotation.y)
	
	# Place block
	# if (buildable):
	if (event is InputEventMouseButton and Input.is_action_just_pressed("left_click")):
		if (Input.is_action_pressed("ready_block")):
			var click_pos : Vector4 = getClickPosition(event.position)
			# click_pos.w == 0, no hit, return
			if (click_pos.w == 0): return
			
			# click_pos.w == 1, hit
			var vec_pos := Vector3(click_pos.x, click_pos.y, click_pos.z)
			placeBlock.emit(vec_pos, "")
			
	# Adjusts the block
	if event.is_action_pressed("menu_left"): # Left first to handle shift + tab vs tab
		scrollBlock.emit(false)
		scrollBlock.emit(false)
	elif event.is_action_pressed("menu_right"):
		scrollBlock.emit(true)
		scrollBlock.emit(true)
	
	# Scrolls the camera
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if cameraDist.scale <= Vector3(20, 20, 20):
				$Camera/SpringArm3D.scale += Vector3(0.1, 0.1, 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if cameraDist.scale >= Vector3.ONE:
				$Camera/SpringArm3D.scale -= Vector3(0.1, 0.1, 0.1)
			


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 2
	
	# From Jus:
	# Get the input direcdtion and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var moveDirection : Vector3 = (camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if moveDirection:
		velocity.x = moveDirection.x * SPEED * sprint
		velocity.z = moveDirection.z * SPEED * sprint
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# Water touching logic
	if is_on_floor() and inWater:
		damage(0.25)
		
		if direction == 0: # Forward
			self.position.x += 0.1 * waterSpeed
		elif direction == -2: # Left
			self.position.z -= 0.1 * waterSpeed
		elif direction == 2: # Right
			self.position.z += 0.1 * waterSpeed
		elif direction == 1: # Forward/Right
			self.position.x += 0.1 * waterSpeed
			self.position.z += 0.1 * waterSpeed
		elif direction == -1: # Forward/Left
			self.position.x += 0.1 * waterSpeed
			self.position.z -= 0.1 * waterSpeed
	
	# block preview
	# if (buildable):
	if (Input.is_action_pressed("ready_block")):
		var click_pos : Vector4 = getClickPosition(mousePos)
		# click_pos.w == 0, no hit, return
		if (click_pos.w == 0): return
		
		# click_pos.w == 1, hit
		var vec_pos := Vector3(click_pos.x, click_pos.y, click_pos.z)
		previewBlock.emit(vec_pos, "")
	else:
		unpreviewBlock.emit()
	
	move_and_slide()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	getPlayerBlocks()
	
	# Updates Player Display
	updateMoney()
	updateHealth()
	
	for block in bpz.blocks:
		var path = block.resource_path
		var name = path.get_file().get_basename()
		var count = -1
		name[0] = name[0].to_upper()
		for char in name:
			count += 1
			if char == "_":
				name[count] = " "
		blocks.append(name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !Globals.launched:
		var bpz = get_parent().get_node("BlockPlacementZone")
		cblockDis.text = "Current block = " + str(blocks[bpz.blockIndex]) + "\n     " + str(blockCountList[bpz.blockIndex])
	else:
		cblockDis.text = ""
		
	if poisoned:
		poisonTick()

# General and Display Functions

# Updates Money Display
func updateMoney():
	moneyDis.text = "$" + str(money)
# Updates Money
func adjMoney(operation: bool, change: int): # True = Add, False = Subtract
	if operation:
		self.money += change
	else:
		if self.money >= change:
			self.money -= change
		else:
			return false
	updateMoney()
	return true

# Updates Health Display
func updateHealth():
	var intHealth = int(health)
	if !intHealth:
		intHealth += 1
	healthDis.text = str(intHealth) + " HP"
	
	if health <= 0:
		die()

func damage(amount):
	health -= amount
	updateHealth()

func die():
	pass # Do something later

# Interact with water function
func enterWater():
	damage(5) # Chunk of damage when first touching water
	touchWater += 1
	inWater = true
func exitWater():
	touchWater -= 1
	if touchWater <= 0:
		inWater = false
func turn(newDir):
	direction = newDir

# Hitting a damaging object function
func hitObject():
	hit = true
func exitObject():
	hit = false

# Poison functions
func enterPoison():
	poisoned = true
func exitPoison():
	poisoned = false
func poisonTick():
	health *= 0.9975
	updateHealth()

# Fast area functions
func changeSpeed(area: bool, up: bool): # True = fastArea, False = crazyArea -- True = speed up, false = slow down
	var change
	if up:
		change = 1
	else:
		change = -1
	
	if area:
		waterSpeed += change * 6.5
	else:
		waterSpeed += change * 2


# click screen input
func getClickPosition(pos : Vector2):
	var cam = $Camera/SpringArm3D/Camera3D
	var ray = $Camera/SpringArm3D/Camera3D/RayCast3D
	ray.global_rotation = Vector3(0.0, 0.0, 0.0)
	ray.target_position = cam.project_ray_normal(pos) * placeBlockDistance
	ray.force_raycast_update()
	# if no collision then return with all zeros
	if (!ray.is_colliding()): return Vector4(0.0, 0.0, 0.0, 0.0)
	
	# if collision, return collision (and w = 1 for success)
	# new location is collision point plus half a unit in face normal direction
	var hit_loc = ray.get_collision_point() + (0.5 * ray.get_collision_normal())
	
	return Vector4(hit_loc.x, hit_loc.y, hit_loc.z, 1.0)

func getPlayerBlocks():
	blockCountList.clear()
	# DELETE LATER - THIS IS FOR ADDING 55 BLOCKS FOR ALL BLOCKS
	for i in range(0, len(bpz.blocks)):
		blockCountList.append(55)

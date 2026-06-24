extends Node3D

@onready var world = $"../.."
@onready var ship = $"../../Ship"
@onready var player = $"../../Player"

# Types of rocks
@onready var bigRock = preload("res://Scenes/Water_Areas/Objects/big_rock.tscn")
@onready var lilRock = preload("res://Scenes/Water_Areas/Objects/lil_rock.tscn")

# Specific Events
@onready var acidCloud = preload("res://Scenes/Water_Areas/Objects/acid_cloud.tscn")
@onready var evilCannon = preload("res://Scenes/Water_Areas/Objects/evil_cannon.tscn")
@onready var ballista = preload("res://Scenes/Water_Areas/Objects/ballista.tscn")

# Number of rocks
@export var numLilRocks = 10
@export var numBigRocks = 3

# Number of specific obstaces
@export var numAcidClouds = 0
@export var numEvilCannons = 0
@export var numBallistas = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var l = (self.get_node("Water").get_node("MeshInstance3D").mesh.get_aabb().size.x / 2) - 2
	var w = (self.get_node("Water").get_node("MeshInstance3D").mesh.get_aabb().size.z / 2) - 2
	var h = 1
	if self.get_node("BackWall") and self.get_node("FrontWall"):
		h = 5 - self.get_node("FrontWall").get_node("MeshInstance3D").mesh.get_aabb().size.y
	loadRocks(l, w, h)
	loadClouds(l, w)
	loadCannons(l, w)
	loadBallistas(l, w)

# PRE-GAME LOADING FUNCTIONS

func loadRocks(l: int, w: int, h: int):
	for i in range(numLilRocks):
		# Sets up newLilRock
		var newLilRock = lilRock.instantiate()
		# Sets up the position of the newLilRock
		newLilRock.position = Vector3(randi_range(-l, l), randf_range(h - 1.5, h), randi_range(-w, w))
		newLilRock.scale = Vector3(randf_range(1, 2), randf_range(1, 2), randf_range(1, 3))
		newLilRock.rotation.x = randi_range(0, 359)
		newLilRock.rotation.y = randi_range(0, 359)
		newLilRock.rotation.z = randi_range(0, 359)
		
		# Makes newLilRock a child of the scene
		add_child(newLilRock)
		
	for i in range(numBigRocks):
		# Sets up newBigRock
		var newBigRock = bigRock.instantiate()
		# Sets up the position of the newBigRock
		newBigRock.position = Vector3(randi_range(-l, l), randi_range(h - 3, h + 1), randi_range(-w, w))
		newBigRock.scale = Vector3(randf_range(0.5, 2), randf_range(0.5, 1), randf_range(0.5, 2))
		newBigRock.rotation.x = randi_range(0, 359)
		newBigRock.rotation.y = randi_range(0, 359)
		newBigRock.rotation.z = randi_range(0, 359)
		
		# Makes newBigRock a child of the scene
		add_child(newBigRock)

func loadClouds(l: int, w: int):
	for i in range(numAcidClouds):
		# Sets up newLilRock
		var newCloud = acidCloud.instantiate()
		# Sets up the position of the newLilRock
		newCloud.position = Vector3(randi_range(-l, l), randf_range(34,37), randi_range(-w, w))
		newCloud.rotation.y = randi_range(0, 359)
		
		# Makes newLilRock a child of the scene
		add_child(newCloud)

func loadCannons(l: int, w: int):
	for i in range(numEvilCannons):
		# Sets up newCannon
		var newCannon = evilCannon.instantiate()
		# Sets up the position of the newCannon
		var side = [w + 2, - (w + 2)].pick_random()
		newCannon.position = Vector3(randi_range(-l, l), randi_range(5, 10), side)
		if side == w + 2:
			newCannon.rotation.y = PI / 2
		else:
			newCannon.rotation.y = - (PI / 2)
		
		# Makes newCannon a child of the scene
		add_child(newCannon)

func loadBallistas(l: int, w: int):
	for i in range(numBallistas):
		# Sets up newBallista
		var newBallista = ballista.instantiate()
		# Sets up the position of the newLilRock
		newBallista.position = Vector3(randi_range(-l, l), randf_range(5, 25), randi_range(-w, w))
		
		# Makes newLilRock a child of the scene
		add_child(newBallista)

func _physics_process(delta: float) -> void:
	for body in $Water/WaterArea.get_overlapping_bodies():
		if body.is_in_group("Ship") or body.is_in_group("player"):
			var selfDir = self.rotation.y
			if self.is_in_group("Corner"):
				await get_tree().create_timer(0.5).timeout
				if (is_equal_approx(selfDir, (PI / 2))) or (is_equal_approx(selfDir, - (PI / 2))):  # Entire area facing left, or forward turning left
					body.turn(-1)
				elif (selfDir == 0) or (is_equal_approx(selfDir, PI)): # Entire area facing right, or forward turning right
					body.turn(1)
			else:
				if selfDir == 0:
					body.turn(0)
				elif is_equal_approx(selfDir, - (PI / 2)):
					body.turn(2)
				elif is_equal_approx(selfDir, (PI / 2)):
					body.turn(-2)

# DURING GAME AREA ENTERING FUNCTIONS

func _on_win_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		world.unlaunch(true)

func _on_water_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Ship"):
		print("Touching water")
		body.enterWater()
		
		if self.is_in_group("Incline"):
			if body.is_in_group("Ship"):
				body.incline = true
		
		if self.is_in_group("SpeedUp"):
			if self.numLilRocks == 25:
				body.changeSpeed(true, true)
			else:
				print(self.name)
				body.changeSpeed(false, true)
		
		# layer specific events:
		if !body.is_in_group("Ship"):
			
			# Specific Water Areas
			if self.is_in_group("hasPoison"):
				body.enterPoison()


func _on_water_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Ship"):
		body.exitWater()
		
		# Specific Water Areas
		
		if self.is_in_group("Incline"):
			if body.is_in_group("Ship"):
				body.incline = false
		
		if self.is_in_group("SpeedUp"):
			if self.numLilRocks == 25:
				body.changeSpeed(true, false)
			else:
				body.changeSpeed(false, false)
		
		if !body.is_in_group("Ship"):
			if self.is_in_group("hasPoison"):
				body.exitPoison()


func _on_tide_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		$TideAnimation.play("Wave")


func _on_tide_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		$TideAnimation.play("RESET")

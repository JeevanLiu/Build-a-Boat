extends Node3D

@onready var world = $".."
@onready var player = $"../Player"

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

# DURING GAME AREA ENTERING FUNCTIONS

func _on_win_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("You win")
		player.adjMoney(true, 100 + int(world.numAreas * 1.2))
		player.position = Vector3(-20, 11, 0)
		world.unlaunch()
		$"../Player/LaunchButton".show()


func _on_water_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("Ship"):
		body.enterWater()
		
		var selfDir = self.rotation.y
		if selfDir == 0:
			body.direction = 0
		elif is_equal_approx(selfDir, - (PI / 2)):
			body.direction = 2
		elif is_equal_approx(selfDir, (PI / 2)):
			body.direction = -2
		
		if self.is_in_group("Incline"):
			if body.is_in_group("Ship"):
				body.incline = true
				body.waterFlowMax = 10 # Shhhhhhh
		
		if self.is_in_group("SpeedUp"):
			if body.is_in_group("player"):
				if self.name == "FastArea":
					body.changeSpeed(true)
				else:
					body.changeSpeed(false)
			else:
				if self.name == "FastArea":
					body.waterFlowMax += 30
				else:
					body.waterFlowMax += 10
		
		# Corner turning
		if self.is_in_group("Corner"):
			if (is_equal_approx(selfDir, (PI / 2))) or (is_equal_approx(selfDir, - (PI / 2))):  # Entire area facing left, or forward turning left
				body.direction = -1
			elif (selfDir == 0) or (is_equal_approx(selfDir, PI)): # Entire area facing right, or forward turning right
				body.direction = 1
		
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
				if body.waterFlowMax == 10:
					body.waterFlowMax = 6 # Shhhhhhh
		
		if self.is_in_group("SpeedUp"):
			if body.is_in_group("player"):
				if self.name == "FastArea":
					body.changeSpeed(true)
				else:
					body.changeSpeed(false)
			else:
				if body.waterFlowMax > 15:
					if self.name == "FastArea":
						body.waterFlowMax -= 30
					else:
						body.waterFlowMax -= 10
					
		
		if !body.is_in_group("Ship"):
			if self.is_in_group("hasPoison"):
				body.exitPoison()


func _on_tide_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and Globals.launched:
		$TideAnimation.play("Wave")


func _on_tide_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		$TideAnimation.play("RESET")

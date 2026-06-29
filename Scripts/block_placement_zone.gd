extends Node3D

# Types of blocks
@onready var block = preload("res://Scenes/Blocks/block.tscn")
@onready var stoneBlock = preload("res://Scenes/Blocks/stone_block.tscn")
@onready var luckyBlock = preload("res://Scenes/Blocks/lucky_block.tscn")
@onready var obsidian = preload("res://Scenes/Blocks/obsidian.tscn")
@onready var chair = preload("res://Scenes/Blocks/basic_chair.tscn")
@onready var woodBlock = preload("res://Scenes/Blocks/wood_block.tscn")
@onready var tnt = preload("res://Scenes/Blocks/tnt_block.tscn")
@onready var grassBlock = preload("res://Scenes/Blocks/grass_block.tscn")
@onready var vampireBlock = preload("res://Scenes/Blocks/vampire_block.tscn")
@onready var glassBlock = preload("res://Scenes/Blocks/glass_block.tscn")
@onready var basicBlock = preload("res://Scenes/Blocks/basic_block.tscn")
@onready var healthBlock = preload("res://Scenes/Blocks/health_block.tscn")

# Dev Block (maybe fun gamemode later)
@onready var infinityBlock = preload("res://Scenes/Blocks/infinity_block.tscn")
@onready var infinityChair = preload("res://Scenes/Blocks/infinity_chair.tscn")

@onready var blocks = [block, stoneBlock, luckyBlock, obsidian, chair, woodBlock, tnt, grassBlock, vampireBlock, glassBlock, basicBlock, healthBlock, infinityBlock, infinityChair]
@onready var blockIndex = 0
@onready var test_blocc = blocks[blockIndex]

@onready var player = get_node("/root/World1/Player")
@onready var ships = get_node("/root/World1/ShipParts")
@onready var shipScript = load("res://Scripts/ship.gd")

# funny preview blocc
var preview_blocc


# min and max location
var min : Vector3
var max : Vector3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(get_path())
	min = ($PlacementZoneRange.global_position - $PlacementZoneRange.shape.size*.5).round()
	max = ($PlacementZoneRange.global_position + $PlacementZoneRange.shape.size*.5).round()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func notValidLocation(location : Vector3):
	if location.x < min.x or location.y < min.y or location.z < min.z: return true
	if location.x > max.x or location.y > max.y or location.z > max.z: return true
	return false

func placeBlock(location : Vector3, id : String):
	player.blockCountList[blockIndex] -= 1
	if player.blockCountList[blockIndex] < 0:
		player.blockCountList[blockIndex] += 1
	else:
		location = location.round()
		print(min, location, max)
		if (notValidLocation(location)): return
		
		var blocc = test_blocc.instantiate()
		blocc.previewMode = false
		blocc.global_position = location
		
		if ships.get_child_count() == 0:
			createShip(blocc)
		else:
			if !addRoutine(blocc, location):
				createShip(blocc)

#region previewBlock

func previewBlock(location : Vector3, id : String):
	location = location.round()
	if (notValidLocation(location)): return
	
	createPreviewBlock()
	preview_blocc.global_position = location

# preview block handling
func createPreviewBlock():
	if (preview_blocc): return # skip if already exists
	
	preview_blocc = test_blocc.instantiate()
	preview_blocc.previewMode = true
	self.add_child(preview_blocc)

func deletePreviewBlock():
	if (preview_blocc):
		preview_blocc.queue_free()

#endregion

func createShip(block):
	var newShip = RigidBody3D.new()
	newShip.freeze = true
	newShip.set_script(shipScript)
	ships.add_child(newShip)
	newShip.add_to_group("Ship")
	newShip.add_child(block)

func addRoutine(blocc, loc):
	for ship in ships.get_children():
		for block in ship.get_children():
			print("Our diff in length is " + str((loc - block.global_position).length()))
			if (loc - block.global_position).length() < 1.75:
				print("We're a ship!")
				ship.add_child(blocc)
				# Combining ships:
				var shipsL = [ship]
				for i in range(ships.get_child_count()):
					combineShips(shipsL, loc, ship)
				return true

func combineShips(shipsL, loc, ship):
	for ship2 in ships.get_children():
		if !ship2 in shipsL:
			for block2 in ship2.get_children():
					if (loc - block2.global_position).length() < 1.5:
						print("More ships! Combine time!")
						shipsL.append(ship2)
						for moveBlock in ship2.get_children():
							moveBlock.reparent(ship)
						ship2.queue_free()
func scrollBlock(up: bool):
	if up:
		blockIndex += 0.5
	else:
		blockIndex -= 0.5
	if blockIndex < 0:
		blockIndex = blocks.size() - 0.5
	elif blockIndex == blocks.size():
		blockIndex = 0
	test_blocc = blocks[blockIndex]

''' comment jus was using
	var deer = DirAccess.open("user://saves/")
	var saveList : Array[Dictionary] = []
	if deer:
		deer.list_dir_begin()
		var file_name = deer.list_dir_begin()
		file_name = deer.get_next()
		
		# loop through every file in the directory
		while file_name != "":
			# Check if the file is .save
			if not deer.current_is_dir() and file_name.get_file().ends_with(".save"):
				var save_file = FileAccess.open("user://saves/"+file_name, FileAccess.READ)
				if (save_file != null):
					var data = save_file.get_var()
					if (data != null and data.has("savename")):
						# get data for title screen menu
						var save_name = data.savename
						var healthy = data.max_health
						var progress = data.powerstatus
						
						# search for where to put it
						var time = FileAccess.get_modified_time("user://saves/"+file_name)
						# using BINARY INSERTION SORT
						var a = 0
						var b = saveList.size()-1
						var m = a+((b-a)>>1)
						while (a <= b):
							if (time > saveList[m].time):
								b = m-1
								m = a+((b-a)>>1)
							elif (time < saveList[m].time):
								a = m+1
								m = a+((b-a)>>1)
							else: break
						m += 1 # make sure its inserted JUST AFTER that index 
						# reformat save data like this. because i said so.
						var newdict = {
							'file_name' : file_name,
							'save_name' : save_name,
							'health' : healthy,
							'progress' : progress,
							'time' : time
						}
						# insert if in middle, otherwise push_back
						if m >= saveList.size():
							saveList.push_back(newdict)
						else: saveList.insert(m, newdict)
			file_name = deer.get_next() # get next file name in the deerectory
	return saveList
'''

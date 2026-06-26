extends Node2D

# Other things
@onready var player = self.get_parent()
@onready var ships = $"../../ShipParts"

# Cooldown and such vars
@onready var oneAtATime = true
@onready var freezable = false
@onready var jumpable = false
@onready var speedable = false
@onready var blockHealable = false

@onready var abilityList = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setAbilities()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Abilities:

# Freezes the ship for 5 seconds:
func freezeShip():
	if freezable and oneAtATime:
		freezable = false
		for ship in ships.get_children():
			ship.sleeping = true
			ship.freeze = true
		oneAtATime = false
		await get_tree().create_timer(5).timeout
		oneAtATime = true
		for ship in ships.get_children():
			ship.sleeping = false
			ship.freeze = false
		await get_tree().create_timer(30).timeout
		freezable = true

# Ship does hop
func jumpShip():
	if jumpable and oneAtATime:
		jumpable = false
		for ship in ships.get_children():
			ship.specialCase = true
			match ship.direction:
				0:
					ship.linear_velocity = Vector3(12.5, 25, 0)
				-1:
					ship.linear_velocity = Vector3(6, 25, -6)
				1:
					ship.linear_velocity = Vector3(6, 25, 6)
				-2:
					ship.linear_velocity = Vector3(0, 25, -12.5)
				2:
					ship.linear_velocity = Vector3(0, 25, 12.5)
		await get_tree().create_timer(2.5).timeout
		for ship in ships.get_children():
			ship.specialCase = false
		#await get_tree().create_timer(25).timeout
		jumpable = true

# Uncap speed
func uncapSpeed():
	if speedable and oneAtATime:
		speedable = false
		for ship in ships.get_children():
			ship.specialCase = true
		await get_tree().create_timer(10).timeout
		for ship in ships.get_children():
			ship.specialCase = false
		await get_tree().create_timer(60).timeout
		speedable = true

func healBlocks():
	if blockHealable:
		blockHealable = false
		for ship in ships.get_children():
			for child in ship.get_children():
				child.health += 5
				if child.health > child.maxHealth:
					child.health = child.maxHealth
		await get_tree().create_timer(60).timeout
		blockHealable = true


# Activates abilities for use (when launched)
func activateAbilities():
	freezable = true
	jumpable = true
	speedable = true
	blockHealable = true

# Sets abilityList
func setAbilities():
	abilityList.append(freezeShip)
	abilityList.append(jumpShip)
	abilityList.append(uncapSpeed)
	abilityList.append(healBlocks)
	for i in range(6):
		abilityList.append(freezeShip)

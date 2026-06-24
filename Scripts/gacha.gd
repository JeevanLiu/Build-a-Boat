extends Node2D

# Important text/Buttons changing:
@onready var shopButton = $Shop
@onready var exShopButton = $ExitShop
@onready var gacha = $"Gacha Types"
@onready var bg = $Background
@onready var winnings = $Winnings
@onready var winDTimer = $Winnings/Timer

@onready var bpz = $"../../BlockPlacementZone"
@onready var player = $".."

func changeMenu():
	for child in self.get_children():
		if child != winnings:
			child.visible = !child.visible

func _on_exit_shop_pressed() -> void:
	changeMenu()

func _on_shop_pressed() -> void:
	changeMenu()

func _on_gacha_button_pressed() -> void:
	if player.adjMoney(false, 100):
		# Adding to the count
		var blockIndex = randi_range(0, bpz.blocks.size() - 1)
		var numAdded = randi_range(10, 20)
		player.blockCountList[blockIndex] += numAdded
		displayWinnings(numAdded, blockIndex)

func _on_rare_pressed() -> void:
	if player.adjMoney(false, 250):
		# Adding to the count
		var blockIndex = randi_range(0, bpz.blocks.size() - 1)
		var numAdded = randi_range(30, 60)
		player.blockCountList[blockIndex] += numAdded
		displayWinnings(numAdded, blockIndex)

func displayWinnings(numAdded, blockIndex):
	# Display
	winnings.show()
	winnings.text = "You won " + str(numAdded) + " " + str(player.blocks[blockIndex]) + "s"
	winDTimer.start()
	await winDTimer.timeout
	winnings.hide()

extends Node2D

@onready var shopOpen = false

# Important text/Buttons changing:
@onready var shopButton = $Shop
@onready var exShopButton = $ExitShop
@onready var commonGacha = $"Gacha Types/Common"
@onready var rareGacha = $"Gacha Types/Rare"
@onready var bg = $Background
@onready var winnings = $Winnings
@onready var winDTimer = $Winnings/Timer

@onready var bpz = $"../../BlockPlacementZone"
@onready var player = $".."


func screenSwap():
	shopOpen = !shopOpen

func closeChanges():
	shopButton.show()
	commonGacha.hide()
	rareGacha.hide()
	exShopButton.hide()
	bg.hide()

func openChanges():
	shopButton.hide()
	commonGacha.show()
	rareGacha.show()
	exShopButton.show()
	bg.show()

func _on_exit_shop_pressed() -> void:
	screenSwap()
	closeChanges()

func _on_shop_pressed() -> void:
	screenSwap()
	openChanges()

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

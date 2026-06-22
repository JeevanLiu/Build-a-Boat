extends Node2D

@onready var shopOpen = false

# Important text/Buttons changing:
@onready var shopButton = $Shop
@onready var exShopButton = $ExitShop
@onready var gachaButton = $"Gacha Button"
@onready var bg = $Background
@onready var bpz = $"../../BlockPlacementZone"
@onready var player = $".."


func screenSwap():
	shopOpen = !shopOpen

func closeChanges():
	shopButton.show()
	gachaButton.hide()
	exShopButton.hide()
	bg.hide()

func openChanges():
	shopButton.hide()
	gachaButton.show()
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
		var blockIndex = randi_range(0, bpz.blocks.size() - 1)
		var numAdded = randi_range(10, 20)
		player.blockCountList[blockIndex] += numAdded

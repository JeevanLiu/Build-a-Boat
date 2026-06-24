extends Node2D

@onready var world = self.get_parent().get_parent()
@onready var numAreas = $NumAreas

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_settings_pressed() -> void:
	numAreas.text = str(world.numAreas)
	changeMenu()

func changeMenu():
	for child in self.get_children():
		if child != $Settings and child != $LaunchButton:
			child.visible = !child.visible
	$"../Gacha".visible = !$"../Gacha".visible


func _on_restart_pressed() -> void:
	world.unlaunch(false)

func _on_launch_button_pressed() -> void:
	world.launch()
	$LaunchButton.hide()

func _on_change_pressed() -> void:
	if int(numAreas.text) > -1:
		world.numAreas = int(numAreas.text)
	changeMenu()

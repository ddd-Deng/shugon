# MainMenu script - handles the start button
extends Node

func _ready() -> void:
	var button = get_parent().get_node("VBox/StartButton")
	button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	GameManager.start_new_run()

# MainMenu script - handles the start button
extends Node

func _ready() -> void:
	_apply_hd_menu_layout()
	var button = get_parent().get_node("VBox/StartButton")
	button.pressed.connect(_on_start_pressed)

func _apply_hd_menu_layout() -> void:
	var root = get_parent() as Control
	if root == null:
		return
	var vbox = root.get_node("VBox") as VBoxContainer
	var title = root.get_node("VBox/Title") as Label
	var spacer = root.get_node("VBox/Spacer") as Control
	var button = root.get_node("VBox/StartButton") as Button

	vbox.offset_left = -260.0
	vbox.offset_top = -140.0
	vbox.offset_right = 260.0
	vbox.offset_bottom = 140.0
	title.add_theme_font_size_override("font_size", 56)
	spacer.custom_minimum_size = Vector2(0, 32)
	button.custom_minimum_size = Vector2(0, 72)
	button.add_theme_font_size_override("font_size", 30)

func _on_start_pressed() -> void:
	GameManager.start_new_run()

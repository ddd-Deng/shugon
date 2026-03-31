# Game Manager - Global Autoload
# Manages overall game state and transitions between scenes
extends Node

enum GameState {
	MAIN_MENU,
	BATTLE,
	REWARD,
	GAME_OVER,
}

var current_state: GameState = GameState.MAIN_MENU
var run_data: Dictionary = {}  # Stores current run info (hp, skills, etc.)

func _ready() -> void:
	print("[GameManager] Initialized")

func start_new_run() -> void:
	run_data = {
		"player_max_hp": 5,
		"player_hp": 5,
		"floor": 1,
		"skills": [],
	}
	current_state = GameState.BATTLE
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")

func on_battle_won() -> void:
	run_data["floor"] += 1
	# TODO: transition to reward/shop screen
	# For now, load next battle
	current_state = GameState.BATTLE
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")

func on_player_died() -> void:
	current_state = GameState.GAME_OVER
	# TODO: transition to game over screen
	print("[GameManager] Game Over!")

func take_damage(amount: int) -> void:
	run_data["player_hp"] = max(0, run_data["player_hp"] - amount)
	if run_data["player_hp"] <= 0:
		on_player_died()

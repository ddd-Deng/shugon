# Player - The player entity on the battle grid
extends "res://scripts/battle/entity.gd"

signal action_taken(action_type: String)

func _ready() -> void:
	entity_name = "Player"
	max_hp = GameManager.run_data.get("player_max_hp", 5)
	current_hp = GameManager.run_data.get("player_hp", 5)
	facing = 1

func try_move(direction: int, grid: Node) -> bool:
	var new_pos = grid_pos + direction
	if grid.move_entity(self, new_pos):
		grid_pos = new_pos
		facing = direction
		update_visual_position(grid.grid_to_world(grid_pos))
		action_taken.emit("move")
		return true
	return false

func try_move_to(target_pos: int, grid: Node) -> bool:
	# Move to a specific cell (must be adjacent and empty)
	var dist = abs(target_pos - grid_pos)
	if dist != 1:
		return false
	var direction = sign(target_pos - grid_pos)
	return try_move(direction, grid)

func try_attack(grid: Node) -> bool:
	# Basic attack: hit the entity in front of player
	var target_pos = grid_pos + facing
	var target = grid.get_entity_at(target_pos)
	if target and target != self:
		play_attack_effect(facing)
		target.take_damage(1)
		action_taken.emit("attack")
		return true
	return false

func try_attack_at(target_pos: int, grid: Node) -> bool:
	# Attack a specific position (must be adjacent)
	var dist = abs(target_pos - grid_pos)
	if dist != 1:
		return false
	facing = sign(target_pos - grid_pos)
	var target = grid.get_entity_at(target_pos)
	if target and target != self:
		play_attack_effect(facing)
		target.take_damage(1)
		action_taken.emit("attack")
		return true
	return false

func skip_turn() -> void:
	action_taken.emit("skip")

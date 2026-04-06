# Turn Manager - Controls the flow of turns in battle
# Core loop: PLAYER_INPUT -> PLAYER_ACT -> ENEMY_ACT -> resolve -> repeat
extends Node

signal turn_started(turn_number: int)
signal player_input_phase()
signal player_act_phase()
signal enemy_act_phase()
signal turn_ended(turn_number: int)

enum Phase {
	WAITING,         # Not in battle
	PLAYER_INPUT,    # Waiting for player to choose action
	PLAYER_ACT,      # Player action is executing (animation)
	ENEMY_ACT,       # Enemies take their actions
	RESOLVING,       # Check for deaths, win/lose conditions
}

var current_phase: Phase = Phase.WAITING
var turn_number: int = 0
var _is_processing_turn: bool = false

func start_battle() -> void:
	turn_number = 0
	_begin_new_turn()

func _begin_new_turn() -> void:
	turn_number += 1
	current_phase = Phase.PLAYER_INPUT
	turn_started.emit(turn_number)
	player_input_phase.emit()
	print("[TurnManager] Turn %d - Waiting for player input" % turn_number)

# Called by BattleScene when player has chosen and executed their action
func on_player_action_complete() -> void:
	if current_phase != Phase.PLAYER_INPUT:
		return
	current_phase = Phase.PLAYER_ACT
	player_act_phase.emit()
	# After player animation resolves, move to enemy phase
	# The battle scene calls advance_to_enemy_phase() when animation is done
	advance_to_enemy_phase()

func advance_to_enemy_phase() -> void:
	current_phase = Phase.ENEMY_ACT
	enemy_act_phase.emit()
	# Enemies act, then battle scene calls on_enemies_done()

func on_enemies_done() -> void:
	current_phase = Phase.RESOLVING
	# Check win/lose conditions - handled by battle scene
	turn_ended.emit(turn_number)
	# Start next turn
	_begin_new_turn()

func is_player_input_allowed() -> bool:
	return current_phase == Phase.PLAYER_INPUT

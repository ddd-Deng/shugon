# EnemyBase - Base class for all enemy types
# Each enemy type overrides decide_action() to define its AI behavior
extends "res://scripts/battle/entity.gd"

# How many turns until this enemy acts (shown as preview to player)
@export var action_cooldown: int = 2
var turns_until_action: int = 2

# What the enemy intends to do (for telegraph/preview)
enum Intent {
	IDLE,
	MOVE_TOWARD,
	ATTACK,
	SPECIAL,
}
var current_intent: Intent = Intent.IDLE

# Intent display label (created in code)
var _intent_label: Label = null

func _ready() -> void:
	entity_name = "Enemy"
	action_cooldown = max(1, action_cooldown)
	turns_until_action = action_cooldown
	_create_intent_label()

func _create_intent_label() -> void:
	_intent_label = Label.new()
	_intent_label.name = "IntentLabel"
	_intent_label.position = Vector2(-26, -148)
	_intent_label.add_theme_font_size_override("font_size", 18)
	_intent_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(_intent_label)

func update_intent(grid: Node, player_pos: int) -> void:
	# Calculate what this enemy WILL do on its next turn and display it
	if turns_until_action <= 1:
		current_intent = decide_action(grid, player_pos)
	else:
		current_intent = Intent.IDLE
	_update_intent_display()

func _update_intent_display() -> void:
	if not _intent_label:
		return
	match current_intent:
		Intent.ATTACK:
			_intent_label.text = "攻击!"
			_intent_label.add_theme_color_override("font_color", Color.RED)
		Intent.MOVE_TOWARD:
			_intent_label.text = "右移" if facing == 1 else "左移"
			_intent_label.add_theme_color_override("font_color", Color.YELLOW)
		Intent.IDLE:
			if turns_until_action > 1:
				_intent_label.text = "待机(%d)" % (turns_until_action - 1)
			else:
				_intent_label.text = "待机"
			_intent_label.add_theme_color_override("font_color", Color.GRAY)
		Intent.SPECIAL:
			_intent_label.text = "技能!"
			_intent_label.add_theme_color_override("font_color", Color.ORANGE)

func begin_turn() -> void:
	turns_until_action -= 1
	if turns_until_action <= 0:
		turns_until_action = action_cooldown

func _consume_turn_and_check_can_act() -> bool:
	turns_until_action -= 1
	if turns_until_action <= 0:
		turns_until_action = action_cooldown
		return true
	return false

func decide_action(_grid: Node, _player_pos: int) -> Intent:
	# Override in subclasses
	# Default: move toward player, attack if adjacent
	var dist = abs(grid_pos - _player_pos)
	if dist <= 1:
		return Intent.ATTACK
	return Intent.MOVE_TOWARD

func execute_action(grid: Node, player: Node) -> void:
	if not _consume_turn_and_check_can_act():
		current_intent = Intent.IDLE
		_update_intent_display()
		return

	var intent = decide_action(grid, player.grid_pos)
	current_intent = intent

	match intent:
		Intent.MOVE_TOWARD:
			_move_toward_player(grid, player.grid_pos)
		Intent.ATTACK:
			_attack_player(player)
		Intent.IDLE:
			pass  # Do nothing

func _move_toward_player(grid: Node, player_pos: int) -> void:
	var direction = sign(player_pos - grid_pos)
	var new_pos = grid_pos + direction
	if grid.move_entity(self, new_pos):
		grid_pos = new_pos
		facing = direction
		update_visual_position(grid.grid_to_world(grid_pos))

func _attack_player(player: Node) -> void:
	play_attack_effect(sign(player.grid_pos - grid_pos))
	player.take_damage(1)
	print("[%s] attacks player for 1 damage!" % entity_name)

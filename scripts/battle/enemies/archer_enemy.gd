# ArcherEnemy - A ranged enemy that attacks from distance
# Behavior:
#   - If player is 2+ cells away: ranged attack every 3 turns
#   - If player is 1 cell away: retreats instead of attacking
#   - Shows intent: "射！" (shoot) or "后退" (retreat)
extends "res://scripts/battle/enemy_base.gd"

func _ready() -> void:
	super()
	entity_name = "Archer"
	max_hp = 2
	current_hp = 2
	action_cooldown = 3  # Ranged attack every 3 turns
	turns_until_action = 3

# Override decide_action for archer-specific AI
func decide_action(_grid: Node, player_pos: int) -> Intent:
	var dist = abs(grid_pos - player_pos)
	if dist >= 2:
		return Intent.ATTACK  # In range for ranged attack
	else:
		return Intent.MOVE_TOWARD  # Too close, retreat

# Override to show archer-specific intent text
func _update_intent_display() -> void:
	if not _intent_label:
		return
	match current_intent:
		Intent.ATTACK:
			_intent_label.text = "射！"
			_intent_label.add_theme_color_override("font_color", Color.ORANGE)
		Intent.MOVE_TOWARD:
			_intent_label.text = "后退"
			_intent_label.add_theme_color_override("font_color", Color.YELLOW)
		Intent.IDLE:
			if turns_until_action > 1:
				_intent_label.text = "装弹(%d)" % (turns_until_action - 1)
			else:
				_intent_label.text = "装弹"
			_intent_label.add_theme_color_override("font_color", Color.GRAY)
		Intent.SPECIAL:
			_intent_label.text = "蓄力!"
			_intent_label.add_theme_color_override("font_color", Color.PURPLE)

# Archer ranged attack - damages player from distance
func execute_action(grid: Node, player: Node) -> void:
	if not _consume_turn_and_check_can_act():
		current_intent = Intent.IDLE
		_update_intent_display()
		return

	var intent = decide_action(grid, player.grid_pos)
	current_intent = intent

	match intent:
		Intent.ATTACK:
			_ranged_attack(player)
		Intent.MOVE_TOWARD:
			_retreat_from_player(grid, player)
		Intent.IDLE:
			pass

func _ranged_attack(player: Node) -> void:
	# Ranged attack - no lunge animation, just shoot
	play_attack_effect(sign(player.grid_pos - grid_pos))
	player.take_damage(1)
	print("[%s] shoots player for 1 damage!" % entity_name)

func _retreat_from_player(grid: Node, player: Node) -> void:
	# Move away from player (opposite direction of player)
	var direction = sign(grid_pos - player.grid_pos)  # Move away
	if direction == 0:
		direction = -self.facing  # Default to facing opposite
	var new_pos = grid_pos + direction
	if grid.is_empty(new_pos) and grid.is_valid_pos(new_pos):
		grid_pos = new_pos
		facing = direction
		update_visual_position(grid.grid_to_world(grid_pos))
	else:
		# Can't retreat, just face player
		facing = sign(player.grid_pos - grid_pos)
	_update_intent_display()

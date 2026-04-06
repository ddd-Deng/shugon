# BattleScene - Main battle controller
# Coordinates grid, player, enemies, turn flow, and rendering
extends Node2D

@onready var turn_manager: Node = $TurnManager
@onready var grid: Node = $Grid
@onready var player: Node2D = $Player
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hp_label: Label = $UILayer/HpLabel
@onready var turn_label: Label = $UILayer/TurnLabel
@onready var info_label: Label = $UILayer/InfoLabel
@onready var grid_visual: Node2D = $GridVisual

var enemies: Array = []
var _player_acted: bool = false
var _battle_over: bool = false

# Grid cell visuals
var _cell_rects: Array = []
var _hover_cell: int = -1

# Skill bar buttons
var _skill_buttons: Array = []  # Array of Button
var _defend_button: Button = null
var _skip_button: Button = null
var _energy_label: Label = null

# Skill range preview cells (highlighted when hovering a skill button)
var _previewing_skill: int = -1

@export var enemy_turn_start_delay: float = 0.35
@export var enemy_action_interval: float = 0.2
@export var enemy_turn_end_delay: float = 0.2

var _base_scene_pos: Vector2 = Vector2.ZERO
var _shake_tween: Tween = null

func _ready() -> void:
	_base_scene_pos = position
	_setup_battle()
	_create_skill_bar()
	turn_manager.player_input_phase.connect(_on_player_input_phase)
	turn_manager.enemy_act_phase.connect(_on_enemy_act_phase)
	turn_manager.turn_ended.connect(_on_turn_ended)
	player.action_taken.connect(_on_player_action_taken)
	player.hp_changed.connect(_on_player_hp_changed)
	player.energy_changed.connect(_on_energy_changed)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_entity_damaged)
	turn_manager.start_battle()

func _setup_battle() -> void:
	grid.setup(9)
	grid.place_entity(player, 1)
	player.grid_pos = 1
	player.position = grid.grid_to_world(1)
	_spawn_enemy(5)
	_spawn_enemy(7)
	_update_ui()
	_draw_grid()
	_update_all_enemy_intents()

func _create_skill_bar() -> void:
	# Energy display
	_energy_label = Label.new()
	_energy_label.position = Vector2(8, 32)
	_energy_label.add_theme_font_size_override("font_size", 10)
	_energy_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	ui_layer.add_child(_energy_label)
	_update_energy_display()

	# Skill buttons - positioned at bottom center
	var bar_y = 188
	var btn_size = Vector2(36, 22)
	var gap = 3
	var total_btns = player.skills.size() + 2  # skills + defend + skip
	var total_width = total_btns * (btn_size.x + gap) - gap
	var start_x = (384 - total_width) / 2

	# Skill buttons
	for i in range(player.skills.size()):
		var skill = player.skills[i]
		var btn = Button.new()
		btn.text = skill.icon_text
		btn.position = Vector2(start_x + i * (btn_size.x + gap), bar_y)
		btn.size = btn_size
		btn.add_theme_font_size_override("font_size", 8)
		btn.tooltip_text = "%s (%d能量)\n%s" % [skill.skill_name, skill.energy_cost, skill.description]
		btn.pressed.connect(_on_skill_button_pressed.bind(i))
		btn.mouse_entered.connect(_on_skill_button_hover.bind(i))
		btn.mouse_exited.connect(_on_skill_button_unhover)
		ui_layer.add_child(btn)
		_skill_buttons.append(btn)

	# Defend button
	var def_x = start_x + player.skills.size() * (btn_size.x + gap)
	_defend_button = Button.new()
	_defend_button.text = "盾"
	_defend_button.position = Vector2(def_x, bar_y)
	_defend_button.size = btn_size
	_defend_button.add_theme_font_size_override("font_size", 8)
	_defend_button.tooltip_text = "防御\n减少1点伤害，获得1能量"
	_defend_button.pressed.connect(_on_defend_button_pressed)
	ui_layer.add_child(_defend_button)

	# Skip button
	var skip_x = def_x + btn_size.x + gap
	_skip_button = Button.new()
	_skip_button.text = "等"
	_skip_button.position = Vector2(skip_x, bar_y)
	_skip_button.size = btn_size
	_skip_button.add_theme_font_size_override("font_size", 8)
	_skip_button.tooltip_text = "跳过回合\n获得1能量"
	_skip_button.pressed.connect(_on_skip_button_pressed)
	ui_layer.add_child(_skip_button)

func _spawn_enemy(pos: int) -> void:
	var enemy_node = Node2D.new()
	var enemy_script = load("res://scripts/battle/enemies/slime_enemy.gd")
	enemy_node.set_script(enemy_script)
	add_child(enemy_node)
	grid.place_entity(enemy_node, pos)
	enemy_node.grid_pos = pos
	enemy_node.facing = -1
	enemy_node.position = grid.grid_to_world(pos)
	enemy_node.died.connect(_on_enemy_died.bind(enemy_node))
	enemy_node.damaged.connect(_on_entity_damaged)
	enemies.append(enemy_node)
	var sprite = ColorRect.new()
	sprite.color = Color.INDIAN_RED
	sprite.size = Vector2(24, 24)
	sprite.position = Vector2(-12, -24)
	enemy_node.add_child(sprite)
	var elabel = Label.new()
	elabel.name = "HpLabel"
	elabel.text = str(enemy_node.current_hp)
	elabel.position = Vector2(-8, -36)
	elabel.add_theme_font_size_override("font_size", 8)
	enemy_node.add_child(elabel)

# --- Input handling ---

func _input(event: InputEvent) -> void:
	if not turn_manager.is_player_input_allowed() or _player_acted or _battle_over:
		return

	# Keyboard: movement and shortcuts
	if event.is_action_pressed("move_left"):
		if player.try_move(-1, grid):
			_finish_player_action()
	elif event.is_action_pressed("move_right"):
		if player.try_move(1, grid):
			_finish_player_action()
	elif event.is_action_pressed("action_confirm"):
		# Space/Enter = use first skill (basic slash)
		_try_use_skill(0)
	elif event.is_action_pressed("skip_turn"):
		player.skip_turn()
		_finish_player_action()

	# Mouse click on grid = movement only (no click-to-attack)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_grid_click(event.position)

func _process(_delta: float) -> void:
	if not turn_manager.is_player_input_allowed() or _battle_over:
		_set_hover_cell(-1)
		return
	var mouse_pos = get_viewport().get_mouse_position()
	var cell = grid.world_to_grid(mouse_pos)
	_set_hover_cell(cell)

func _handle_grid_click(mouse_pos: Vector2) -> void:
	var clicked_cell = grid.world_to_grid(mouse_pos)
	if clicked_cell < 0:
		return
	# Only movement on grid click
	if grid.is_empty(clicked_cell):
		if player.try_move_to(clicked_cell, grid):
			_finish_player_action()

# --- Skill button handlers ---

func _on_skill_button_pressed(skill_index: int) -> void:
	_try_use_skill(skill_index)

func _try_use_skill(skill_index: int) -> void:
	if not turn_manager.is_player_input_allowed() or _player_acted or _battle_over:
		return
	if player.try_use_skill(skill_index, grid):
		_clear_skill_preview()
		_finish_player_action()

func _on_defend_button_pressed() -> void:
	if not turn_manager.is_player_input_allowed() or _player_acted or _battle_over:
		return
	player.try_defend()
	_finish_player_action()

func _on_skip_button_pressed() -> void:
	if not turn_manager.is_player_input_allowed() or _player_acted or _battle_over:
		return
	player.skip_turn()
	_finish_player_action()

# --- Skill range preview ---

func _on_skill_button_hover(skill_index: int) -> void:
	if not turn_manager.is_player_input_allowed() or _battle_over:
		return
	_previewing_skill = skill_index
	_refresh_grid_visuals()

func _on_skill_button_unhover() -> void:
	_previewing_skill = -1
	_refresh_grid_visuals()

func _clear_skill_preview() -> void:
	_previewing_skill = -1

# --- Turn flow ---

func _finish_player_action() -> void:
	_player_acted = true
	_update_enemy_hp_labels()
	_cleanup_dead_enemies()
	_refresh_grid_visuals()
	_update_energy_display()
	_update_skill_button_states()
	if enemies.is_empty():
		_on_battle_won()
		return
	turn_manager.on_player_action_complete()

func _on_player_input_phase() -> void:
	_player_acted = false
	player.on_turn_start()
	_update_all_enemy_intents()
	_refresh_grid_visuals()
	_update_skill_button_states()
	_update_energy_display()
	info_label.text = "点击格子移动 | 使用技能攻击"

func _on_enemy_act_phase() -> void:
	info_label.text = "敌人回合..."
	_set_all_buttons_disabled(true)
	await _play_turn_banner("敌人回合")
	await get_tree().create_timer(enemy_turn_start_delay).timeout
	for enemy in enemies:
		if _battle_over:
			break
		if not enemy.is_dead:
			enemy.execute_action(grid, player)
			_refresh_grid_visuals()
			await get_tree().create_timer(enemy_action_interval).timeout
	_cleanup_dead_enemies()
	# Check if player dodged (no damage taken) — energy reward handled by defense
	await get_tree().create_timer(enemy_turn_end_delay).timeout
	_refresh_grid_visuals()
	turn_manager.on_enemies_done()

func _on_turn_ended(_turn: int) -> void:
	_update_ui()

func _on_player_action_taken(_action_type: String) -> void:
	pass

func _on_player_hp_changed(current: int, max_val: int) -> void:
	hp_label.text = "生命: %d/%d" % [current, max_val]
	GameManager.run_data["player_hp"] = current

func _on_energy_changed(_current: int, _max_val: int) -> void:
	_update_energy_display()
	_update_skill_button_states()

func _on_player_died() -> void:
	_battle_over = true
	info_label.text = "你已败北（占位）"
	_set_all_buttons_disabled(true)
	GameManager.on_player_died()

func _on_enemy_died(enemy: Node) -> void:
	grid.remove_entity(enemy)
	enemies.erase(enemy)
	enemy.queue_free()
	# Kill reward: +1 energy
	player.gain_energy(1)

func _on_battle_won() -> void:
	_battle_over = true
	info_label.text = "战斗胜利！（占位）"
	_set_all_buttons_disabled(true)
	print("[BattleScene] All enemies defeated!")

func _cleanup_dead_enemies() -> void:
	var to_remove: Array = []
	for enemy in enemies:
		if enemy.is_dead:
			to_remove.append(enemy)
	for enemy in to_remove:
		_on_enemy_died(enemy)

# --- Intent system ---

func _update_all_enemy_intents() -> void:
	for enemy in enemies:
		if not enemy.is_dead:
			enemy.update_intent(grid, player.grid_pos)

# --- UI updates ---

func _update_enemy_hp_labels() -> void:
	for enemy in enemies:
		var label = enemy.get_node_or_null("HpLabel")
		if label:
			label.text = str(enemy.current_hp)

func _update_ui() -> void:
	hp_label.text = "生命: %d/%d" % [player.current_hp, player.max_hp]
	turn_label.text = "回合: %d" % turn_manager.turn_number
	_update_energy_display()

func _update_energy_display() -> void:
	if _energy_label:
		var bar = ""
		for i in range(player.max_energy):
			if i < player.current_energy:
				bar += "◆"
			else:
				bar += "◇"
		_energy_label.text = "能量: %s" % bar

func _update_skill_button_states() -> void:
	var can_act = turn_manager.is_player_input_allowed() and not _player_acted and not _battle_over
	for i in range(_skill_buttons.size()):
		var btn = _skill_buttons[i]
		var skill = player.skills[i]
		var affordable = player.current_energy >= skill.energy_cost
		btn.disabled = not can_act or not affordable
		# Show energy cost on button
		if skill.energy_cost > 0:
			btn.text = "%s%d" % [skill.icon_text, skill.energy_cost]
		else:
			btn.text = skill.icon_text
	if _defend_button:
		_defend_button.disabled = not can_act
	if _skip_button:
		_skip_button.disabled = not can_act

func _set_all_buttons_disabled(disabled: bool) -> void:
	for btn in _skill_buttons:
		btn.disabled = disabled
	if _defend_button:
		_defend_button.disabled = disabled
	if _skip_button:
		_skip_button.disabled = disabled

func _play_turn_banner(text_value: String) -> void:
	info_label.text = text_value
	info_label.scale = Vector2.ONE
	info_label.modulate = Color(1, 1, 1, 0.6)
	var tween = create_tween()
	tween.tween_property(info_label, "scale", Vector2(1.1, 1.1), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(info_label, "scale", Vector2.ONE, 0.08).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(info_label, "modulate:a", 1.0, 0.08)
	await tween.finished

func _on_entity_damaged(_amount: int, hit_world_pos: Vector2) -> void:
	_spawn_hit_pulse(hit_world_pos)
	_play_screen_shake(2.5)

func _spawn_hit_pulse(hit_world_pos: Vector2) -> void:
	var pulse = Polygon2D.new()
	pulse.polygon = PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3),
	])
	pulse.color = Color(1.0, 0.75, 0.25, 0.95)
	pulse.position = hit_world_pos
	add_child(pulse)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse, "scale", Vector2(2.8, 2.8), 0.14).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "rotation", 0.25, 0.14)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.14)
	tween.finished.connect(pulse.queue_free)

func _play_screen_shake(intensity: float) -> void:
	if _shake_tween:
		_shake_tween.kill()
	position = _base_scene_pos
	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "position", _base_scene_pos + Vector2(-intensity, 0), 0.03)
	_shake_tween.tween_property(self, "position", _base_scene_pos + Vector2(intensity, 0), 0.03)
	_shake_tween.tween_property(self, "position", _base_scene_pos + Vector2(-intensity * 0.5, 0), 0.02)
	_shake_tween.tween_property(self, "position", _base_scene_pos, 0.02)

# --- Grid visuals ---

func _set_hover_cell(cell: int) -> void:
	if cell != _hover_cell:
		if _hover_cell >= 0 and _hover_cell < _cell_rects.size():
			_cell_rects[_hover_cell].color = _get_cell_color(_hover_cell)
		_hover_cell = cell
	_apply_hover_color()

func _apply_hover_color() -> void:
	if _hover_cell < 0 or _hover_cell >= _cell_rects.size():
		return
	var dist = abs(_hover_cell - player.grid_pos)
	if grid.is_empty(_hover_cell) and dist == 1:
		_cell_rects[_hover_cell].color = Color(0.15, 0.5, 0.15, 0.7)
	else:
		_cell_rects[_hover_cell].color = Color(0.3, 0.3, 0.4, 0.5)

func _refresh_grid_visuals() -> void:
	for i in range(_cell_rects.size()):
		_cell_rects[i].color = _get_cell_color(i)
	# Skill range preview overlay
	if _previewing_skill >= 0 and _previewing_skill < player.skills.size():
		var skill = player.skills[_previewing_skill]
		var targets = skill.get_target_positions(player.grid_pos, player.facing)
		for t in targets:
			if t >= 0 and t < _cell_rects.size():
				var entity = grid.get_entity_at(t)
				if entity and entity != player:
					_cell_rects[t].color = Color(0.7, 0.15, 0.15, 0.8)  # Enemy in range: red
				else:
					_cell_rects[t].color = Color(0.5, 0.35, 0.1, 0.6)  # Empty range: orange
	_apply_hover_color()

func _get_cell_color(cell: int) -> Color:
	var entity = grid.get_entity_at(cell)
	if entity == player:
		return Color(0.15, 0.25, 0.4, 0.5)
	elif entity:
		return Color(0.35, 0.15, 0.15, 0.5)
	return Color(0.2, 0.2, 0.3, 0.5)

func _draw_grid() -> void:
	_cell_rects.clear()
	for i in range(grid.grid_width):
		var cell = ColorRect.new()
		cell.size = Vector2(30, 30)
		var world_pos = grid.grid_to_world(i)
		cell.position = Vector2(world_pos.x - 15, world_pos.y - 28)
		cell.color = _get_cell_color(i)
		grid_visual.add_child(cell)
		_cell_rects.append(cell)
		var border = ReferenceRect.new()
		border.size = Vector2(30, 30)
		border.position = cell.position
		border.border_color = Color(0.4, 0.4, 0.5, 0.8)
		border.border_width = 1.0
		border.editor_only = false
		grid_visual.add_child(border)

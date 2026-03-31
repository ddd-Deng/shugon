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

# Grid cell visuals for hover highlighting
var _cell_rects: Array = []
var _hover_cell: int = -1

# Attack button reference
var _attack_button: Button = null
var _skip_button: Button = null

func _ready() -> void:
	_setup_battle()
	_create_action_buttons()
	turn_manager.player_input_phase.connect(_on_player_input_phase)
	turn_manager.enemy_act_phase.connect(_on_enemy_act_phase)
	turn_manager.turn_ended.connect(_on_turn_ended)
	player.action_taken.connect(_on_player_action_taken)
	player.hp_changed.connect(_on_player_hp_changed)
	player.died.connect(_on_player_died)
	turn_manager.start_battle()

func _setup_battle() -> void:
	grid.setup(9)
	# Place player at center-left
	grid.place_entity(player, 1)
	player.grid_pos = 1
	player.position = grid.grid_to_world(1)
	# Spawn test enemies
	_spawn_enemy(6)
	_spawn_enemy(8)
	_update_ui()
	_draw_grid()
	_update_all_enemy_intents()

func _create_action_buttons() -> void:
	# Attack button
	_attack_button = Button.new()
	_attack_button.text = "Attack"
	_attack_button.position = Vector2(290, 190)
	_attack_button.size = Vector2(40, 18)
	_attack_button.add_theme_font_size_override("font_size", 8)
	_attack_button.pressed.connect(_on_attack_button_pressed)
	ui_layer.add_child(_attack_button)
	# Skip button
	_skip_button = Button.new()
	_skip_button.text = "Skip"
	_skip_button.position = Vector2(335, 190)
	_skip_button.size = Vector2(40, 18)
	_skip_button.add_theme_font_size_override("font_size", 8)
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
	enemies.append(enemy_node)
	# Add placeholder visual
	var sprite = ColorRect.new()
	sprite.color = Color.INDIAN_RED
	sprite.size = Vector2(24, 24)
	sprite.position = Vector2(-12, -24)
	enemy_node.add_child(sprite)
	# HP label for enemy
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

	# Keyboard input
	if event.is_action_pressed("move_left"):
		if player.try_move(-1, grid):
			_finish_player_action()
	elif event.is_action_pressed("move_right"):
		if player.try_move(1, grid):
			_finish_player_action()
	elif event.is_action_pressed("action_confirm"):
		if player.try_attack(grid):
			_finish_player_action()
	elif event.is_action_pressed("skip_turn"):
		player.skip_turn()
		_finish_player_action()

	# Mouse click on grid
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_grid_click(event.position)

func _process(_delta: float) -> void:
	# Update hover highlight
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

	var entity_at_cell = grid.get_entity_at(clicked_cell)

	if entity_at_cell and entity_at_cell != player:
		# Clicked on an enemy — try to attack it
		if player.try_attack_at(clicked_cell, grid):
			_finish_player_action()
	elif grid.is_empty(clicked_cell):
		# Clicked on empty cell — try to move there
		if player.try_move_to(clicked_cell, grid):
			_finish_player_action()

func _on_attack_button_pressed() -> void:
	if not turn_manager.is_player_input_allowed() or _player_acted or _battle_over:
		return
	if player.try_attack(grid):
		_finish_player_action()

func _on_skip_button_pressed() -> void:
	if not turn_manager.is_player_input_allowed() or _player_acted or _battle_over:
		return
	player.skip_turn()
	_finish_player_action()

# --- Turn flow ---

func _finish_player_action() -> void:
	_player_acted = true
	_update_enemy_hp_labels()
	_cleanup_dead_enemies()
	if enemies.is_empty():
		_on_battle_won()
		return
	turn_manager.on_player_action_complete()

func _on_player_input_phase() -> void:
	_player_acted = false
	_update_all_enemy_intents()
	_update_button_states(true)
	info_label.text = "Click cell to move | Click enemy to attack"

func _on_enemy_act_phase() -> void:
	info_label.text = "Enemy turn..."
	_update_button_states(false)
	for enemy in enemies:
		if not enemy.is_dead:
			enemy.execute_action(grid, player)
	_cleanup_dead_enemies()
	turn_manager.on_enemies_done()

func _on_turn_ended(_turn: int) -> void:
	_update_ui()

func _on_player_action_taken(_action_type: String) -> void:
	pass

func _on_player_hp_changed(current: int, max_val: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, max_val]
	GameManager.run_data["player_hp"] = current

func _on_player_died() -> void:
	_battle_over = true
	info_label.text = "You died! (placeholder)"
	_update_button_states(false)
	GameManager.on_player_died()

func _on_enemy_died(enemy: Node) -> void:
	grid.remove_entity(enemy)
	enemies.erase(enemy)
	enemy.queue_free()

func _on_battle_won() -> void:
	_battle_over = true
	info_label.text = "Battle Won! (placeholder)"
	_update_button_states(false)
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
	hp_label.text = "HP: %d/%d" % [player.current_hp, player.max_hp]
	turn_label.text = "Turn: %d" % turn_manager.turn_number

func _update_button_states(enabled: bool) -> void:
	if _attack_button:
		_attack_button.disabled = not enabled
	if _skip_button:
		_skip_button.disabled = not enabled

# --- Grid visuals ---

func _set_hover_cell(cell: int) -> void:
	if cell == _hover_cell:
		return
	# Reset old hover
	if _hover_cell >= 0 and _hover_cell < _cell_rects.size():
		_cell_rects[_hover_cell].color = _get_cell_color(_hover_cell)
	_hover_cell = cell
	# Set new hover
	if _hover_cell >= 0 and _hover_cell < _cell_rects.size():
		var entity = grid.get_entity_at(_hover_cell)
		var dist = abs(_hover_cell - player.grid_pos)
		if entity and entity != player and dist == 1:
			# Adjacent enemy: red highlight
			_cell_rects[_hover_cell].color = Color(0.6, 0.15, 0.15, 0.7)
		elif grid.is_empty(_hover_cell) and dist == 1:
			# Adjacent empty: green highlight
			_cell_rects[_hover_cell].color = Color(0.15, 0.5, 0.15, 0.7)
		else:
			# Not reachable: dim highlight
			_cell_rects[_hover_cell].color = Color(0.3, 0.3, 0.4, 0.5)

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
		# Cell border
		var border = ReferenceRect.new()
		border.size = Vector2(30, 30)
		border.position = cell.position
		border.border_color = Color(0.4, 0.4, 0.5, 0.8)
		border.border_width = 1.0
		border.editor_only = false
		grid_visual.add_child(border)

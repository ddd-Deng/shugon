# Player - The player entity on the battle grid
extends "res://scripts/battle/entity.gd"

signal action_taken(action_type: String)
signal energy_changed(current: int, max_val: int)

const SkillDataClass = preload("res://scripts/battle/skill_data.gd")

# --- Energy system ---
var max_energy: int = 5
var current_energy: int = 0

# --- Defense ---
var is_defending: bool = false
var defend_reduction: int = 1  # Damage reduced when defending

# --- Skills ---
var skills: Array = []  # Array of SkillData

func _ready() -> void:
	entity_name = "Player"
	max_hp = GameManager.run_data.get("player_max_hp", 5)
	current_hp = GameManager.run_data.get("player_hp", 5)
	facing = 1
	current_energy = 0
	_init_default_skills()

func _init_default_skills() -> void:
	skills = [
		SkillDataClass.create_basic_slash(),
		SkillDataClass.create_thrust(),
		SkillDataClass.create_cleave(),
		SkillDataClass.create_heavy_strike(),
	]

# --- Energy ---

func gain_energy(amount: int) -> void:
	current_energy = min(max_energy, current_energy + amount)
	energy_changed.emit(current_energy, max_energy)

func spend_energy(amount: int) -> bool:
	if current_energy < amount:
		return false
	current_energy -= amount
	energy_changed.emit(current_energy, max_energy)
	return true

# --- Override take_damage to account for defense ---

func take_damage(amount: int) -> void:
	var actual = amount
	if is_defending:
		actual = max(0, amount - defend_reduction)
		is_defending = false
	# Call parent
	if is_dead:
		return
	current_hp = max(0, current_hp - actual)
	hp_changed.emit(current_hp, max_hp)
	if actual > 0:
		damaged.emit(actual, position)
		_play_hit_effect(actual)
	else:
		_spawn_floating_text("格挡!", Color(0.4, 0.8, 1.0))
	print("[%s] took %d damage (raw %d), HP: %d/%d" % [entity_name, actual, amount, current_hp, max_hp])
	if current_hp <= 0:
		_on_die()

# --- Movement ---

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
	var dist = abs(target_pos - grid_pos)
	if dist != 1:
		return false
	var direction = sign(target_pos - grid_pos)
	return try_move(direction, grid)

# --- Skill-based attack ---

func try_use_skill(skill_index: int, grid: Node) -> bool:
	if skill_index < 0 or skill_index >= skills.size():
		return false
	var skill: SkillData = skills[skill_index]
	var energy_cost = max(0, skill.energy_cost)
	var skill_damage = max(0, skill.damage)
	# Check energy
	if current_energy < energy_cost:
		return false

	# Resolve target positions and clamp to valid grid cells.
	var target_cells = skill.get_target_positions(grid_pos, facing)
	var valid_cells: Array[int] = []
	for cell_pos in target_cells:
		if grid.is_valid_pos(cell_pos):
			valid_cells.append(cell_pos)

	# Execute cast first: skill should be castable even when no enemy is hit.
	spend_energy(energy_cost)
	play_attack_effect(facing)

	var hit_any = false
	var hit_count = 0
	var total_damage = 0

	# Apply damage to all valid targets in range.
	for cell_pos in valid_cells:
		var target = grid.get_entity_at(cell_pos)
		if target and target != self:
			hit_any = true
			hit_count += 1
			total_damage += skill_damage
			target.take_damage(skill_damage)

	if not hit_any:
		_spawn_floating_text("落空", Color(0.8, 0.8, 0.9, 1.0))
	else:
		print("[Player] Skill %s hit %d target(s), total damage %d" % [skill.skill_name, hit_count, total_damage])

	action_taken.emit("skill:" + skill.skill_name)
	return true

# --- Defense ---

func try_defend() -> void:
	is_defending = true
	gain_energy(1)
	_spawn_floating_text("防御", Color(0.4, 0.8, 1.0))
	action_taken.emit("defend")

# --- Skip ---

func skip_turn() -> void:
	gain_energy(1)
	action_taken.emit("skip")

# --- Called at start of player turn to reset per-turn states ---

func on_turn_start() -> void:
	is_defending = false

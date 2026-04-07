# SkillData - Data class defining a single skill
# Used by player to determine attack behavior
class_name SkillData
extends RefCounted

# --- Core properties ---
var skill_name: String = ""
var description: String = ""
var energy_cost: int = 0
var damage: int = 1
var attack_range: int = 1  # How many cells away it can hit

# Direction mode: "facing" = only in player's facing direction
#                 "both"   = hits both left and right
#                 "behind" = only behind the player
var direction_mode: String = "facing"

# --- Visual ---
var icon_color: Color = Color.WHITE  # Placeholder color for the skill button
var icon_text: String = "?"  # Short text shown on button if no icon texture

# --- Factory methods for built-in skills ---

static func create_basic_slash() -> SkillData:
	var s = SkillData.new()
	s.skill_name = "斩击"
	s.description = "向前方1格造成1点伤害"
	s.energy_cost = 0
	s.damage = 1
	s.attack_range = 1
	s.direction_mode = "facing"
	s.icon_color = Color(0.8, 0.8, 0.8)
	s.icon_text = "斩"
	return s

static func create_thrust() -> SkillData:
	var s = SkillData.new()
	s.skill_name = "突刺"
	s.description = "向前方2格造成1点伤害"
	s.energy_cost = 1
	s.damage = 1
	s.attack_range = 2
	s.direction_mode = "facing"
	s.icon_color = Color(0.4, 0.7, 1.0)
	s.icon_text = "刺"
	return s

static func create_cleave() -> SkillData:
	var s = SkillData.new()
	s.skill_name = "横扫"
	s.description = "同时攻击左右各1格，造成1点伤害"
	s.energy_cost = 2
	s.damage = 1
	s.attack_range = 1
	s.direction_mode = "both"
	s.icon_color = Color(1.0, 0.6, 0.2)
	s.icon_text = "扫"
	return s

static func create_heavy_strike() -> SkillData:
	var s = SkillData.new()
	s.skill_name = "重击"
	s.description = "向前方1格造成2点伤害"
	s.energy_cost = 2
	s.damage = 2
	s.attack_range = 1
	s.direction_mode = "facing"
	s.icon_color = Color(1.0, 0.3, 0.3)
	s.icon_text = "重"
	return s

# --- Utility ---

func get_target_positions(caster_pos: int, caster_facing: int) -> Array[int]:
	# Returns all grid positions this skill would hit
	var targets: Array[int] = []
	var range_steps = max(1, attack_range)
	var dir = caster_facing
	if dir == 0:
		dir = 1
	match direction_mode:
		"facing":
			for i in range(1, range_steps + 1):
				targets.append(caster_pos + dir * i)
		"both":
			for i in range(1, range_steps + 1):
				targets.append(caster_pos + i)
				targets.append(caster_pos - i)
		"behind":
			for i in range(1, range_steps + 1):
				targets.append(caster_pos - dir * i)
	return targets

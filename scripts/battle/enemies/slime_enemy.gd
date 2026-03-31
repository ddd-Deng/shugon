# SlimeEnemy - A basic enemy that slowly approaches and attacks
extends "res://scripts/battle/enemy_base.gd"

func _ready() -> void:
	super()  # 必须调用父类_ready()，否则意图标签不会创建
	entity_name = "Slime"
	max_hp = 2
	current_hp = 2
	action_cooldown = 2
	turns_until_action = 2

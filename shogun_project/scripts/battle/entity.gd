# Entity - Base class for anything that exists on the grid
# Both player and enemies inherit from this
extends Node2D

signal hp_changed(current_hp: int, max_hp: int)
signal died()

@export var entity_name: String = "Entity"
@export var max_hp: int = 3
@export var current_hp: int = 3
@export var grid_pos: int = 0
@export var facing: int = 1  # 1 = right, -1 = left

var is_dead: bool = false

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	print("[%s] took %d damage, HP: %d/%d" % [entity_name, amount, current_hp, max_hp])
	if current_hp <= 0:
		_on_die()

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func _on_die() -> void:
	is_dead = true
	died.emit()
	print("[%s] died!" % entity_name)

func update_visual_position(world_pos: Vector2) -> void:
	# Smoothly move to grid position
	var tween = create_tween()
	tween.tween_property(self, "position", world_pos, 0.15).set_ease(Tween.EASE_OUT)

# Entity - Base class for anything that exists on the grid
# Both player and enemies inherit from this
extends Node2D

signal hp_changed(current_hp: int, max_hp: int)
signal died()
signal damaged(amount: int, world_pos: Vector2)

@export var entity_name: String = "Entity"
@export var max_hp: int = 3
@export var current_hp: int = 3
@export var grid_pos: int = 0
@export var facing: int = 1  # 1 = right, -1 = left

var is_dead: bool = false
var _visual_anchor: Vector2 = Vector2.ZERO

func _ready() -> void:
	_visual_anchor = position

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	damaged.emit(amount, position)
	_play_hit_effect(amount)
	print("[%s] took %d damage, HP: %d/%d" % [entity_name, amount, current_hp, max_hp])
	if current_hp <= 0:
		_on_die()

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func _on_die() -> void:
	is_dead = true
	_spawn_floating_text("KO", Color(1.0, 0.82, 0.22, 1.0))
	died.emit()
	print("[%s] died!" % entity_name)

func update_visual_position(world_pos: Vector2) -> void:
	# Smoothly move to grid position
	_visual_anchor = world_pos
	var tween = create_tween()
	tween.tween_property(self, "position", world_pos, 0.15).set_ease(Tween.EASE_OUT)

func play_attack_effect(direction: int = facing) -> void:
	if is_dead:
		return
	var dir = direction
	if dir == 0:
		dir = facing
	var lunge_distance = 5.0
	var lunge_target = _visual_anchor + Vector2(lunge_distance * dir, 0)
	var tween = create_tween()
	tween.tween_property(self, "position", lunge_target, 0.05).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", _visual_anchor, 0.08).set_ease(Tween.EASE_IN)

func _play_hit_effect(amount: int) -> void:
	_spawn_floating_text("-%d" % amount, Color(1.0, 0.35, 0.35, 1.0))
	var flash = create_tween()
	flash.tween_property(self, "modulate", Color(1.45, 0.42, 0.42, 1.0), 0.05)
	flash.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.12)

	var shake = create_tween()
	shake.tween_property(self, "position", _visual_anchor + Vector2(-4, 0), 0.03)
	shake.tween_property(self, "position", _visual_anchor + Vector2(4, 0), 0.03)
	shake.tween_property(self, "position", _visual_anchor + Vector2(-2, 0), 0.02)
	shake.tween_property(self, "position", _visual_anchor, 0.02)

func _spawn_floating_text(text_value: String, text_color: Color) -> void:
	var pop = Label.new()
	pop.text = text_value
	pop.position = Vector2(-10, -52)
	pop.add_theme_font_size_override("font_size", 9)
	pop.add_theme_color_override("font_color", text_color)
	add_child(pop)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pop, "position", pop.position + Vector2(0, -14), 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(pop, "modulate:a", 0.0, 0.35)
	tween.finished.connect(pop.queue_free)

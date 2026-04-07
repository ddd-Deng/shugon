# Grid - 1D battle grid data structure
# Manages positions of all entities on a horizontal line
extends Node

signal entity_moved(entity: Node, from_pos: int, to_pos: int)
signal entity_added(entity: Node, pos: int)
signal entity_removed(entity: Node, pos: int)

var cell_size: int = 120  # Pixels per grid cell at 1080p
var grid_offset_x: float = 0.0
var grid_offset_y: float = 0.0
var cell_click_top: float = -102.0
var cell_click_bottom: float = 22.0

var grid_width: int = 9  # Number of cells (configurable per battle)
var _cells: Array = []  # Each element is null or entity reference

func _ready() -> void:
	_init_grid(grid_width)
	_recalculate_layout(get_viewport().get_visible_rect().size)

func _init_grid(width: int) -> void:
	grid_width = width
	_cells.clear()
	_cells.resize(width)
	for i in range(width):
		_cells[i] = null

func setup(width: int, viewport_size: Vector2 = Vector2.ZERO) -> void:
	_init_grid(width)
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport().get_visible_rect().size
	_recalculate_layout(viewport_size)

func _recalculate_layout(viewport_size: Vector2) -> void:
	grid_offset_x = floor((viewport_size.x - grid_width * cell_size) * 0.5)
	grid_offset_y = floor(viewport_size.y * 0.68)
	cell_click_top = -cell_size * 0.85
	cell_click_bottom = cell_size * 0.18

# --- Position queries ---

func is_valid_pos(pos: int) -> bool:
	return pos >= 0 and pos < grid_width

func is_empty(pos: int) -> bool:
	return is_valid_pos(pos) and _cells[pos] == null

func get_entity_at(pos: int):
	if is_valid_pos(pos):
		return _cells[pos]
	return null

func get_entity_pos(entity: Node) -> int:
	return _cells.find(entity)

# --- Entity management ---

func place_entity(entity: Node, pos: int) -> bool:
	if not is_empty(pos):
		return false
	_cells[pos] = entity
	entity_added.emit(entity, pos)
	return true

func remove_entity(entity: Node) -> void:
	var pos = _cells.find(entity)
	if pos != -1:
		_cells[pos] = null
		entity_removed.emit(entity, pos)

func move_entity(entity: Node, new_pos: int) -> bool:
	if not is_empty(new_pos):
		return false
	var old_pos = _cells.find(entity)
	if old_pos == -1:
		return false
	_cells[old_pos] = null
	_cells[new_pos] = entity
	entity_moved.emit(entity, old_pos, new_pos)
	return true

# --- Utility ---

func grid_to_world(pos: int) -> Vector2:
	return Vector2(grid_offset_x + pos * cell_size + cell_size * 0.5, grid_offset_y)

func get_all_entities() -> Array:
	var result: Array = []
	for cell in _cells:
		if cell != null:
			result.append(cell)
	return result

func get_entities_in_range(center: int, radius: int) -> Array:
	var result: Array = []
	for i in range(max(0, center - radius), min(grid_width, center + radius + 1)):
		if _cells[i] != null:
			result.append(_cells[i])
	return result

func get_distance(pos_a: int, pos_b: int) -> int:
	return abs(pos_a - pos_b)

func world_to_grid(world_pos: Vector2) -> int:
	# Convert a world/mouse position to grid index, returns -1 if outside grid
	var relative_x = world_pos.x - grid_offset_x
	var relative_y = world_pos.y - grid_offset_y
	if relative_y < cell_click_top or relative_y > cell_click_bottom:
		return -1
	var idx = int(floor(relative_x / cell_size))
	if idx >= 0 and idx < grid_width:
		return idx
	return -1

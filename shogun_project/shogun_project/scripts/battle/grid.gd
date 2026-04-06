# Grid - 1D battle grid data structure
# Manages positions of all entities on a horizontal line
extends Node

signal entity_moved(entity: Node, from_pos: int, to_pos: int)
signal entity_added(entity: Node, pos: int)
signal entity_removed(entity: Node, pos: int)

const CELL_SIZE: int = 32  # Pixels per grid cell
const GRID_OFFSET_X: int = 48  # Left margin in pixels
const GRID_OFFSET_Y: int = 140  # Vertical position of the grid

var grid_width: int = 9  # Number of cells (configurable per battle)
var _cells: Array = []  # Each element is null or entity reference

func _ready() -> void:
	_init_grid(grid_width)

func _init_grid(width: int) -> void:
	grid_width = width
	_cells.clear()
	_cells.resize(width)
	for i in range(width):
		_cells[i] = null

func setup(width: int) -> void:
	_init_grid(width)

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
	return Vector2(GRID_OFFSET_X + pos * CELL_SIZE + CELL_SIZE / 2, GRID_OFFSET_Y)

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
	var relative_x = world_pos.x - GRID_OFFSET_X
	var relative_y = world_pos.y - GRID_OFFSET_Y
	# Check vertical bounds (cell is drawn from y-28 to y+2 relative to anchor)
	if relative_y < -28 or relative_y > 2:
		return -1
	var idx = int(relative_x / CELL_SIZE)
	if idx >= 0 and idx < grid_width:
		return idx
	return -1

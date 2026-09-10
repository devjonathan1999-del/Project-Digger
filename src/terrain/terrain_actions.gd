class_name TerrainActions
extends RefCounted

const DIG_COST := 1
const MOVE_COST := 2
const FUSE_COST := 2

var energy_remaining: int = 0

var _model: TerrainModel
var _catalog := MaterialCatalog.new()
var _initial_snapshot: Dictionary = {}
var _initial_energy: int = 0
var _history: Array[Dictionary] = []
var _active := false

func begin_prepare(model: TerrainModel, energy: int) -> void:
    _model = model
    energy_remaining = maxi(0, energy)
    _initial_snapshot = _model.snapshot()
    _initial_energy = energy_remaining
    _history.clear()
    _active = true

func dig(pos: Vector2i) -> bool:
    if not _active or energy_remaining < DIG_COST:
        return false
    var cell := _model.get_cell(pos)
    if cell == null:
        return false
    var material := _catalog.get_def(cell.material_id)
    if material == null or not material.diggable:
        return false

    _remember_state()
    _model.set_cell(pos, null)
    energy_remaining -= DIG_COST
    return true

func move(from_cells: Array[Vector2i], offset: Vector2i) -> bool:
    if not _active or energy_remaining < MOVE_COST or from_cells.is_empty() or offset == Vector2i.ZERO:
        return false

    var selected: Dictionary = {}
    var moved_cells: Dictionary = {}
    for source in from_cells:
        if selected.has(source):
            return false
        var cell := _model.get_cell(source)
        if cell == null:
            return false
        selected[source] = true
        moved_cells[source] = cell

    for source in from_cells:
        var destination := source + offset
        if destination.x < 0 or destination.y < 0 or destination.x >= _model.width or destination.y >= _model.height:
            return false
        if not selected.has(destination) and _model.get_cell(destination) != null:
            return false

    _remember_state()
    for source in from_cells:
        _model.set_cell(source, null)
    for source in from_cells:
        _model.set_cell(source + offset, moved_cells[source])

    energy_remaining -= MOVE_COST
    return true

func fuse(target: Vector2i, stabilizer_source: Vector2i) -> bool:
    if not _active or energy_remaining < FUSE_COST or target == stabilizer_source:
        return false

    var target_cell := _model.get_cell(target)
    var source_cell := _model.get_cell(stabilizer_source)
    if target_cell == null or source_cell == null or source_cell.material_id != &"stabilizer":
        return false

    var stabilizer := _catalog.get_def(&"stabilizer")
    if stabilizer == null:
        return false

    _remember_state()
    target_cell.stability_modifier += stabilizer.stability_bonus
    _model.set_cell(stabilizer_source, null)
    energy_remaining -= FUSE_COST
    return true

func undo() -> bool:
    if not _active or _history.is_empty():
        return false
    var previous: Dictionary = _history.pop_back()
    _model.restore(previous["terrain"])
    energy_remaining = int(previous["energy"])
    return true

func commit() -> void:
    if not _active:
        return
    _history.clear()
    _initial_snapshot = {}
    _active = false

func cancel() -> void:
    if not _active:
        return
    _model.restore(_initial_snapshot)
    energy_remaining = _initial_energy
    _history.clear()
    _initial_snapshot = {}
    _active = false

func _remember_state() -> void:
    _history.append({
        "terrain": _model.snapshot(),
        "energy": energy_remaining,
    })

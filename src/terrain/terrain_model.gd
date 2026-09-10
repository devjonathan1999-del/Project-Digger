class_name TerrainModel
extends RefCounted

var width: int
var height: int
var _cells: Array = []

func _init(p_width: int = 0, p_height: int = 0) -> void:
    width = max(0, p_width)
    height = max(0, p_height)
    _cells.resize(width * height)

func _is_in_bounds(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height

func _index(pos: Vector2i) -> int:
    return pos.y * width + pos.x

func get_cell(pos: Vector2i) -> TerrainCell:
    if not _is_in_bounds(pos):
        return null
    return _cells[_index(pos)]

func set_cell(pos: Vector2i, cell: TerrainCell) -> bool:
    if not _is_in_bounds(pos):
        return false
    _cells[_index(pos)] = cell
    return true

func snapshot() -> Dictionary:
    var serialized_cells: Array = []
    serialized_cells.resize(_cells.size())
    for i in range(_cells.size()):
        var cell: TerrainCell = _cells[i]
        if cell == null:
            serialized_cells[i] = null
        else:
            serialized_cells[i] = {
                "material_id": String(cell.material_id),
                "stability_modifier": cell.stability_modifier,
            }
    return {
        "width": width,
        "height": height,
        "cells": serialized_cells,
    }

func restore(state: Dictionary) -> void:
    width = max(0, int(state.get("width", 0)))
    height = max(0, int(state.get("height", 0)))
    _cells.clear()
    _cells.resize(width * height)

    var serialized_cells: Array = state.get("cells", [])
    var count := mini(_cells.size(), serialized_cells.size())
    for i in range(count):
        var entry = serialized_cells[i]
        if entry == null:
            _cells[i] = null
        else:
            _cells[i] = TerrainCell.new(
                StringName(entry.get("material_id", "")),
                float(entry.get("stability_modifier", 0.0))
            )

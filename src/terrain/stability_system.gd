class_name StabilitySystem
extends RefCounted

enum { STABLE, FRAGILE, CRITICAL }

var _catalog := MaterialCatalog.new()

func classify(model: TerrainModel) -> Dictionary:
    var supported: Dictionary = {}
    var changed := true

    while changed:
        changed = false
        var next_supported := supported.duplicate()
        for y in range(model.height - 1, -1, -1):
            for x in range(model.width):
                var pos := Vector2i(x, y)
                var cell := model.get_cell(pos)
                if cell == null or next_supported.has(pos):
                    continue
                var state := _classify_cell(model, pos, supported)
                if state != CRITICAL:
                    next_supported[pos] = true
                    changed = true
        supported = next_supported

    var result: Dictionary = {}
    for y in range(model.height):
        for x in range(model.width):
            var pos := Vector2i(x, y)
            if model.get_cell(pos) != null:
                result[pos] = _classify_cell(model, pos, supported)
    return result

func resolve(model: TerrainModel, max_iterations: int = 128) -> Array[Dictionary]:
    var movements: Array[Dictionary] = []
    var limit := maxi(0, max_iterations)

    for _iteration in range(limit):
        var states := classify(model)
        var moved := false
        for y in range(model.height - 1, -1, -1):
            for x in range(model.width):
                var from := Vector2i(x, y)
                if states.get(from, STABLE) != CRITICAL:
                    continue
                var to := from + Vector2i.DOWN
                if to.y >= model.height or model.get_cell(to) != null:
                    continue
                var cell := model.get_cell(from)
                if cell == null:
                    continue
                model.set_cell(from, null)
                model.set_cell(to, cell)
                movements.append({
                    "from": from,
                    "to": to,
                    "material_id": cell.material_id,
                })
                moved = true
        if not moved:
            break

    return movements

func _classify_cell(model: TerrainModel, pos: Vector2i, supported: Dictionary) -> int:
    var cell := model.get_cell(pos)
    if cell == null:
        return STABLE
    var material := _catalog.get_def(cell.material_id)
    if material == null:
        return CRITICAL

    var support_score := _support_score(model, pos, supported)
    var threshold := material.mass / maxf(0.1, material.strength + cell.stability_modifier)
    if support_score >= threshold:
        return STABLE
    if support_score >= threshold * 0.5:
        return FRAGILE
    return CRITICAL

func _support_score(model: TerrainModel, pos: Vector2i, supported: Dictionary) -> float:
    if pos.y == model.height - 1:
        return 1.0

    var score := 0.0
    var below := pos + Vector2i.DOWN
    if supported.has(below):
        score += 1.0

    var left := pos + Vector2i.LEFT
    if supported.has(left):
        score += 0.5

    var right := pos + Vector2i.RIGHT
    if supported.has(right):
        score += 0.5

    return score

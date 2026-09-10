class_name AncientNetwork
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _catalog := MaterialCatalog.new()

func is_relay_connected(model: TerrainModel, source: Vector2i, relay: Vector2i) -> bool:
    if not _in_bounds(model, source) or not _in_bounds(model, relay):
        return false
    if source == relay:
        return true

    var queue: Array[Vector2i] = [source]
    var visited: Dictionary = {source: true}
    var head := 0

    while head < queue.size():
        var current := queue[head]
        head += 1

        for direction in DIRECTIONS:
            var next := current + direction
            if next == relay:
                return true
            if not _in_bounds(model, next) or visited.has(next):
                continue

            var cell := model.get_cell(next)
            if cell == null:
                continue
            var material := _catalog.get_def(cell.material_id)
            if material == null or not material.conductive:
                continue

            visited[next] = true
            queue.append(next)

    return false

func _in_bounds(model: TerrainModel, pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.y >= 0 and pos.x < model.width and pos.y < model.height

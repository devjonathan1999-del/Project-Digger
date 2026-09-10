class_name TerrainRenderer
extends Node2D

const CELL_SIZE := 16

var _model: TerrainModel
var _analysis: Dictionary = {}
var _selection: Array[Vector2i] = []
var _motion_preview: Array[Dictionary] = []
var _motion_progress := 0.0

func set_model(model: TerrainModel) -> void:
    _model = model
    queue_redraw()

func set_analysis(classification: Dictionary) -> void:
    _analysis = classification.duplicate()
    queue_redraw()

func set_selection(cells: Array[Vector2i]) -> void:
    _selection.assign(cells)
    queue_redraw()

func cell_from_screen(screen_pos: Vector2) -> Vector2i:
    var world_pos := get_canvas_transform().affine_inverse() * screen_pos
    var local_pos := to_local(world_pos)
    return Vector2i(
        int(floor(local_pos.x / float(CELL_SIZE))),
        int(floor(local_pos.y / float(CELL_SIZE)))
    )

func animate_movements(movements: Array[Dictionary]) -> void:
    if movements.is_empty():
        queue_redraw()
        return
    _motion_preview = movements.duplicate(true)
    _motion_progress = 0.0
    var tween := create_tween()
    tween.tween_method(_set_motion_progress, 0.0, 1.0, 0.3)
    tween.finished.connect(func() -> void:
        _motion_preview.clear()
        queue_redraw()
    )

func _set_motion_progress(value: float) -> void:
    _motion_progress = value
    queue_redraw()

func _draw() -> void:
    if _model == null:
        return

    for y in range(_model.height):
        for x in range(_model.width):
            var pos := Vector2i(x, y)
            var cell := _model.get_cell(pos)
            if cell == null:
                continue
            var rect := Rect2(Vector2(x * CELL_SIZE, y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
            var variation := float((x * 17 + y * 31) % 3) * 0.025
            draw_rect(rect, _material_color(cell.material_id).lightened(variation), true)

            if _analysis.has(pos):
                draw_rect(rect, _analysis_color(int(_analysis[pos])), true)

    for selected in _selection:
        var selection_rect := Rect2(
            Vector2(selected.x * CELL_SIZE, selected.y * CELL_SIZE),
            Vector2(CELL_SIZE, CELL_SIZE)
        )
        draw_rect(selection_rect.grow(-1.0), Color(0.92, 0.97, 1.0, 0.9), false, 2.0)

    for movement in _motion_preview:
        var from: Vector2i = movement.get("from", Vector2i.ZERO)
        var to: Vector2i = movement.get("to", from)
        var from_px := Vector2(from.x * CELL_SIZE, from.y * CELL_SIZE)
        var to_px := Vector2(to.x * CELL_SIZE, to.y * CELL_SIZE)
        var draw_pos := from_px.lerp(to_px, _motion_progress)
        draw_rect(Rect2(draw_pos, Vector2(CELL_SIZE, CELL_SIZE)), Color(0.92, 0.96, 1.0, 0.32), true)

func _material_color(material_id: StringName) -> Color:
    match material_id:
        &"rock_common":
            return Color("#5f6874")
        &"rock_fragile":
            return Color("#8b7768")
        &"rock_dense":
            return Color("#343c47")
        &"stabilizer":
            return Color("#2b9f9a")
        _:
            return Color("#6b6f75")

func _analysis_color(state: int) -> Color:
    match state:
        StabilitySystem.STABLE:
            return Color(0.22, 0.76, 0.55, 0.16)
        StabilitySystem.FRAGILE:
            return Color(0.96, 0.68, 0.20, 0.24)
        StabilitySystem.CRITICAL:
            return Color(0.95, 0.25, 0.22, 0.30)
        _:
            return Color(0.0, 0.0, 0.0, 0.0)

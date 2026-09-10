class_name TerrainRenderer
extends Node2D

const CELL_SIZE := 16

var _model: TerrainModel
var _analysis: Dictionary = {}
var _selection: Array[Vector2i] = []
var _motion_preview: Array[Dictionary] = []
var _motion_progress := 0.0
var _prepare_mode := false
var _hovered_cell := Vector2i.ZERO
var _has_hover := false

func set_model(model: TerrainModel) -> void:
    _model = model
    queue_redraw()

func set_analysis(classification: Dictionary) -> void:
    _analysis = classification.duplicate()
    queue_redraw()

func set_selection(cells: Array[Vector2i]) -> void:
    _selection.assign(cells)
    queue_redraw()

func set_prepare_mode(enabled: bool) -> void:
    _prepare_mode = enabled
    queue_redraw()

func set_hovered_cell(cell: Vector2i) -> void:
    _hovered_cell = cell
    _has_hover = true
    queue_redraw()

func clear_hovered_cell() -> void:
    _has_hover = false
    queue_redraw()

func cell_from_local(local_pos: Vector2) -> Vector2i:
    return Vector2i(
        int(floor(local_pos.x / float(CELL_SIZE))),
        int(floor(local_pos.y / float(CELL_SIZE)))
    )

func cell_from_screen(screen_pos: Vector2) -> Vector2i:
    var world_pos := get_canvas_transform().affine_inverse() * screen_pos
    return cell_from_local(to_local(world_pos))

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

            var polygon := _cell_polygon(pos)
            var variant := TerrainVisualProfile.detail_variant(pos, cell.material_id)
            var base := TerrainVisualProfile.base_color(cell.material_id).lightened(float(variant) * 0.012)
            draw_colored_polygon(polygon, base)
            _draw_material_detail(pos, cell.material_id, variant)
            _draw_exposed_edges(pos, polygon)

            if _prepare_mode and _analysis.has(pos):
                draw_colored_polygon(polygon, _analysis_color(int(_analysis[pos])))

    for selected in _selection:
        if _model.get_cell(selected) != null:
            _draw_outline(_cell_polygon(selected), Color(0.92, 0.97, 1.0, 0.95), 2.0)

    if _has_hover and _model.get_cell(_hovered_cell) != null:
        var hover_color := Color(0.65, 0.90, 0.96, 0.72) if not _prepare_mode else Color(0.85, 0.95, 1.0, 0.95)
        _draw_outline(_cell_polygon(_hovered_cell), hover_color, 2.0)

    for movement in _motion_preview:
        var from: Vector2i = movement.get("from", Vector2i.ZERO)
        var to: Vector2i = movement.get("to", from)
        var from_px := Vector2(from.x * CELL_SIZE, from.y * CELL_SIZE)
        var to_px := Vector2(to.x * CELL_SIZE, to.y * CELL_SIZE)
        var draw_pos := from_px.lerp(to_px, _motion_progress)
        draw_rect(Rect2(draw_pos + Vector2(1, 1), Vector2(CELL_SIZE - 2, CELL_SIZE - 2)), Color(0.92, 0.96, 1.0, 0.28), true)

func _has_cell(pos: Vector2i) -> bool:
    return _model != null and pos.x >= 0 and pos.y >= 0 and pos.x < _model.width and pos.y < _model.height and _model.get_cell(pos) != null

func _cell_polygon(pos: Vector2i) -> PackedVector2Array:
    var origin := Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)
    var top := TerrainVisualProfile.edge_inset(pos, TerrainVisualProfile.Edge.TOP) if not _has_cell(pos + Vector2i.UP) else 0.0
    var right := TerrainVisualProfile.edge_inset(pos, TerrainVisualProfile.Edge.RIGHT) if not _has_cell(pos + Vector2i.RIGHT) else 0.0
    var bottom := TerrainVisualProfile.edge_inset(pos, TerrainVisualProfile.Edge.BOTTOM) if not _has_cell(pos + Vector2i.DOWN) else 0.0
    var left := TerrainVisualProfile.edge_inset(pos, TerrainVisualProfile.Edge.LEFT) if not _has_cell(pos + Vector2i.LEFT) else 0.0
    return PackedVector2Array([
        origin + Vector2(left, top),
        origin + Vector2(CELL_SIZE - right, top),
        origin + Vector2(CELL_SIZE - right, CELL_SIZE - bottom),
        origin + Vector2(left, CELL_SIZE - bottom),
    ])

func _draw_outline(polygon: PackedVector2Array, color: Color, width: float) -> void:
    if polygon.is_empty():
        return
    var outline := polygon.duplicate()
    outline.append(polygon[0])
    draw_polyline(outline, color, width, true)

func _draw_exposed_edges(pos: Vector2i, polygon: PackedVector2Array) -> void:
    var shade := Color(0.02, 0.035, 0.045, 0.48)
    if not _has_cell(pos + Vector2i.UP):
        draw_line(polygon[0], polygon[1], shade, 1.4, true)
    if not _has_cell(pos + Vector2i.RIGHT):
        draw_line(polygon[1], polygon[2], shade, 1.4, true)
    if not _has_cell(pos + Vector2i.DOWN):
        draw_line(polygon[2], polygon[3], shade, 1.4, true)
    if not _has_cell(pos + Vector2i.LEFT):
        draw_line(polygon[3], polygon[0], shade, 1.4, true)

func _draw_material_detail(pos: Vector2i, material_id: StringName, variant: int) -> void:
    var origin := Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)
    var detail := TerrainVisualProfile.detail_color(material_id)
    match material_id:
        &"rock_fragile":
            var x_shift := 3.0 + float(variant)
            draw_polyline(PackedVector2Array([
                origin + Vector2(x_shift, 4.0),
                origin + Vector2(8.0, 8.0),
                origin + Vector2(6.0 + float(variant), 13.0),
            ]), detail.darkened(0.14), 1.1, true)
        &"stabilizer":
            var center := origin + Vector2(8.0 + float(variant - 1), 8.0)
            draw_colored_polygon(PackedVector2Array([
                center + Vector2(0, -4),
                center + Vector2(3, 0),
                center + Vector2(0, 4),
                center + Vector2(-3, 0),
            ]), detail)
        &"rock_dense":
            if variant <= 1:
                draw_line(origin + Vector2(4, 11), origin + Vector2(12, 9), detail.darkened(0.18), 1.0, true)
        &"rock_common":
            if variant == 0:
                draw_circle(origin + Vector2(10, 6), 1.25, detail.darkened(0.08))

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

class_name ResolutionFx
extends Node2D

var _points: Array[Vector2] = []
var _alpha := 0.0
var _success_point: Variant = null

func play_movements(movements: Array[Dictionary], cell_size: int) -> void:
    _points.clear()
    _success_point = null
    var seen := {}
    for movement in movements:
        var cell: Vector2i = movement.get("to", Vector2i.ZERO)
        if seen.has(cell):
            continue
        seen[cell] = true
        _points.append(Vector2((cell.x + 0.5) * cell_size, (cell.y + 0.5) * cell_size))
        if _points.size() >= 12:
            break

    _alpha = 0.75 if not _points.is_empty() else 0.0
    queue_redraw()
    if _alpha > 0.0:
        var tween := create_tween()
        tween.tween_method(_set_alpha, _alpha, 0.0, 0.35)

func play_success(cell: Vector2i, cell_size: int) -> void:
    _success_point = Vector2((cell.x + 0.5) * cell_size, (cell.y + 0.5) * cell_size)
    _alpha = 1.0
    queue_redraw()
    var tween := create_tween()
    tween.tween_method(_set_alpha, 1.0, 0.0, 0.45)

func _set_alpha(value: float) -> void:
    _alpha = value
    queue_redraw()

func _draw() -> void:
    for point in _points:
        draw_circle(point, 7.0 + (1.0 - _alpha) * 5.0, Color(0.72, 0.67, 0.58, _alpha * 0.40))
    if _success_point != null and _alpha > 0.0:
        draw_circle(_success_point, 12.0 + (1.0 - _alpha) * 16.0, Color(0.30, 0.95, 0.88, _alpha), false, 2.0)

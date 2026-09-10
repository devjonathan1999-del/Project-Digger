class_name AncientOverlay
extends Node2D

var _path: Array[Vector2i] = []
var _relay_pos := Vector2i.ZERO
var _cell_size := 16
var _connected := false
var _pulse_alpha := 0.0

func configure(path: Array[Vector2i], relay_pos: Vector2i, cell_size: int) -> void:
    _path.assign(path)
    _relay_pos = relay_pos
    _cell_size = cell_size
    queue_redraw()

func set_connected(value: bool) -> void:
    _connected = value
    queue_redraw()

func pulse() -> void:
    _pulse_alpha = 1.0
    queue_redraw()
    var tween := create_tween()
    tween.tween_method(_set_pulse_alpha, 1.0, 0.0, 0.28)

func _set_pulse_alpha(value: float) -> void:
    _pulse_alpha = value
    queue_redraw()

func _center(cell: Vector2i) -> Vector2:
    return Vector2((cell.x + 0.5) * _cell_size, (cell.y + 0.5) * _cell_size)

func _draw() -> void:
    if _path.size() >= 2:
        var points := PackedVector2Array()
        for cell in _path:
            points.append(_center(cell))
        var alpha := 0.86 if _connected else 0.24
        var base := Color(0.20, 0.95, 0.92, alpha)
        draw_polyline(points, base, 2.0, true)

        for index in range(0, _path.size(), 3):
            draw_circle(_center(_path[index]), 2.2, Color(0.47, 1.0, 0.96, alpha))

        if _pulse_alpha > 0.0:
            draw_polyline(points, Color(0.65, 1.0, 0.98, _pulse_alpha), 5.0, true)

    var relay_center := _center(_relay_pos)
    draw_circle(relay_center, 11.0, Color(0.08, 0.16, 0.19, 0.92))
    draw_circle(relay_center, 9.0, Color(0.20, 0.95, 0.92, 0.90 if _connected else 0.30))
    draw_circle(relay_center, 4.0, Color("#d6fffb"))
    draw_line(relay_center + Vector2(0, -16), relay_center + Vector2(0, -10), Color(0.28, 0.93, 0.90, 0.65), 2.0, true)

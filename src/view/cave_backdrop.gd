class_name CaveBackdrop
extends Node2D

var _size_px := Vector2(1024, 1152)

func configure(size_cells: Vector2i, cell_size: int) -> void:
    _size_px = Vector2(size_cells.x * cell_size, size_cells.y * cell_size)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, _size_px), Color("#08121b"), true)
    draw_rect(
        Rect2(Vector2(0, _size_px.y * 0.34), Vector2(_size_px.x, _size_px.y * 0.66)),
        Color("#0c1821"),
        true
    )

    var far_arches := PackedVector2Array([
        Vector2(70, _size_px.y),
        Vector2(70, _size_px.y * 0.61),
        Vector2(170, _size_px.y * 0.46),
        Vector2(265, _size_px.y * 0.59),
        Vector2(390, _size_px.y * 0.39),
        Vector2(515, _size_px.y * 0.57),
        Vector2(650, _size_px.y * 0.43),
        Vector2(785, _size_px.y * 0.58),
        Vector2(930, _size_px.y * 0.47),
        Vector2(960, _size_px.y),
    ])
    draw_colored_polygon(far_arches, Color("#101f29"))

    var deep_arches := PackedVector2Array([
        Vector2(140, _size_px.y),
        Vector2(140, _size_px.y * 0.78),
        Vector2(275, _size_px.y * 0.64),
        Vector2(420, _size_px.y * 0.78),
        Vector2(560, _size_px.y * 0.60),
        Vector2(705, _size_px.y * 0.77),
        Vector2(850, _size_px.y * 0.66),
        Vector2(900, _size_px.y),
    ])
    draw_colored_polygon(deep_arches, Color("#0a151e"))

    for x in range(100, int(_size_px.x), 190):
        draw_circle(Vector2(x, _size_px.y * 0.74), 30.0, Color(0.48, 0.31, 0.17, 0.055))

    for x in range(150, int(_size_px.x), 260):
        var glow_center := Vector2(x, _size_px.y * 0.48 + float((x / 10) % 70))
        draw_circle(glow_center, 18.0, Color(0.12, 0.55, 0.58, 0.035))

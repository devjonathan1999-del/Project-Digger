class_name CaveBackdrop
extends Node2D

var _size_px := Vector2(1024, 1152)
var _margin_px := 720.0

func configure(size_cells: Vector2i, cell_size: int) -> void:
    _size_px = Vector2(size_cells.x * cell_size, size_cells.y * cell_size)
    queue_redraw()

func _draw() -> void:
    var bounds := Rect2(
        Vector2(-_margin_px, -_margin_px),
        _size_px + Vector2(_margin_px * 2.0, _margin_px * 2.0)
    )
    draw_rect(bounds, Color("#050b11"), true)

    # Main cave void. The decorative layer deliberately extends beyond the
    # logical terrain bounds so camera framing never reveals the viewport gray.
    draw_rect(Rect2(Vector2.ZERO, _size_px), Color("#08121b"), true)
    draw_rect(
        Rect2(Vector2(0, _size_px.y * 0.34), Vector2(_size_px.x, _size_px.y * 0.66)),
        Color("#0c1821"),
        true
    )

    var far_arches := PackedVector2Array([
        Vector2(-120, _size_px.y),
        Vector2(-80, _size_px.y * 0.57),
        Vector2(90, _size_px.y * 0.66),
        Vector2(185, _size_px.y * 0.43),
        Vector2(285, _size_px.y * 0.61),
        Vector2(405, _size_px.y * 0.37),
        Vector2(525, _size_px.y * 0.58),
        Vector2(655, _size_px.y * 0.41),
        Vector2(795, _size_px.y * 0.60),
        Vector2(940, _size_px.y * 0.45),
        Vector2(_size_px.x + 120, _size_px.y * 0.62),
        Vector2(_size_px.x + 120, _size_px.y),
    ])
    draw_colored_polygon(far_arches, Color("#101f29"))

    var deep_arches := PackedVector2Array([
        Vector2(-100, _size_px.y),
        Vector2(-70, _size_px.y * 0.80),
        Vector2(120, _size_px.y * 0.72),
        Vector2(270, _size_px.y * 0.61),
        Vector2(415, _size_px.y * 0.79),
        Vector2(555, _size_px.y * 0.59),
        Vector2(705, _size_px.y * 0.77),
        Vector2(850, _size_px.y * 0.64),
        Vector2(_size_px.x + 90, _size_px.y * 0.76),
        Vector2(_size_px.x + 90, _size_px.y),
    ])
    draw_colored_polygon(deep_arches, Color("#0a151e"))

    # Dark foreground shoulders soften the impression of a rectangular level
    # boundary without participating in collision or stability.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-_margin_px, -_margin_px),
        Vector2(70, -_margin_px),
        Vector2(48, 150),
        Vector2(76, 280),
        Vector2(42, 430),
        Vector2(70, 610),
        Vector2(35, _size_px.y + _margin_px),
        Vector2(-_margin_px, _size_px.y + _margin_px),
    ]), Color("#071017"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(_size_px.x - 55, -_margin_px),
        Vector2(_size_px.x + _margin_px, -_margin_px),
        Vector2(_size_px.x + _margin_px, _size_px.y + _margin_px),
        Vector2(_size_px.x - 42, _size_px.y + _margin_px),
        Vector2(_size_px.x - 72, 760),
        Vector2(_size_px.x - 46, 580),
        Vector2(_size_px.x - 78, 390),
        Vector2(_size_px.x - 50, 205),
    ]), Color("#071017"))

    for x in range(100, int(_size_px.x), 190):
        draw_circle(Vector2(x, _size_px.y * 0.74), 30.0, Color(0.48, 0.31, 0.17, 0.055))

    for x in range(150, int(_size_px.x), 260):
        var glow_center := Vector2(x, _size_px.y * 0.48 + float((x / 10) % 70))
        draw_circle(glow_center, 18.0, Color(0.12, 0.55, 0.58, 0.035))

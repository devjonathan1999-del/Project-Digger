class_name CaveBackdrop
extends Node2D

var _size_px := Vector2(1024, 1152)
var _margin_px := 720.0

func configure(size_cells: Vector2i, cell_size: int) -> void:
    _size_px = Vector2(size_cells.x * cell_size, size_cells.y * cell_size)
    queue_redraw()

func geology_masses() -> Array:
    var w := _size_px.x
    var h := _size_px.y
    return [
        PackedVector2Array([
            Vector2(0, h * 0.05), Vector2(w * 0.20, h * 0.05),
            Vector2(w * 0.24, h * 0.10), Vector2(w * 0.31, h * 0.13),
            Vector2(w * 0.28, h * 0.18), Vector2(w * 0.21, h * 0.21),
            Vector2(w * 0.18, h * 0.27), Vector2(0, h * 0.30),
        ]),
        PackedVector2Array([
            Vector2(w, h * 0.07), Vector2(w * 0.82, h * 0.07),
            Vector2(w * 0.78, h * 0.14), Vector2(w * 0.75, h * 0.21),
            Vector2(w * 0.79, h * 0.28), Vector2(w * 0.86, h * 0.33),
            Vector2(w, h * 0.35),
        ]),
        PackedVector2Array([
            Vector2(0, h * 0.31), Vector2(w * 0.17, h * 0.30),
            Vector2(w * 0.23, h * 0.35), Vector2(w * 0.27, h * 0.41),
            Vector2(w * 0.22, h * 0.47), Vector2(w * 0.16, h * 0.53),
            Vector2(0, h * 0.54),
        ]),
        PackedVector2Array([
            Vector2(w, h * 0.36), Vector2(w * 0.87, h * 0.35),
            Vector2(w * 0.80, h * 0.40), Vector2(w * 0.75, h * 0.46),
            Vector2(w * 0.79, h * 0.53), Vector2(w * 0.86, h * 0.59),
            Vector2(w, h * 0.60),
        ]),
        PackedVector2Array([
            Vector2(0, h * 0.55), Vector2(w * 0.15, h * 0.54),
            Vector2(w * 0.22, h * 0.59), Vector2(w * 0.28, h * 0.66),
            Vector2(w * 0.25, h * 0.73), Vector2(w * 0.18, h * 0.79),
            Vector2(w * 0.11, h * 0.84), Vector2(0, h * 0.85),
        ]),
        PackedVector2Array([
            Vector2(w, h * 0.61), Vector2(w * 0.87, h * 0.60),
            Vector2(w * 0.80, h * 0.65), Vector2(w * 0.74, h * 0.72),
            Vector2(w * 0.77, h * 0.80), Vector2(w * 0.84, h * 0.86),
            Vector2(w, h * 0.87),
        ]),
        PackedVector2Array([
            Vector2(0, h * 0.84), Vector2(w * 0.13, h * 0.82),
            Vector2(w * 0.20, h * 0.87), Vector2(w * 0.25, h * 0.93),
            Vector2(w * 0.22, h), Vector2(0, h),
        ]),
        PackedVector2Array([
            Vector2(w, h * 0.86), Vector2(w * 0.86, h * 0.84),
            Vector2(w * 0.79, h * 0.89), Vector2(w * 0.73, h * 0.95),
            Vector2(w * 0.76, h), Vector2(w, h),
        ]),
    ]

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

    # Hand-authored midground geology visually anchors playable shelves to the
    # cave walls. It stays behind the terrain and never participates in physics.
    var masses := geology_masses()
    for index in range(masses.size()):
        var mass := masses[index] as PackedVector2Array
        var mass_color := Color("#182630") if index % 2 == 0 else Color("#15232d")
        draw_colored_polygon(mass, mass_color)
        var edge := mass.duplicate()
        if not edge.is_empty():
            edge.append(edge[0])
            draw_polyline(edge, Color(0.18, 0.28, 0.34, 0.35), 1.2, true)

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

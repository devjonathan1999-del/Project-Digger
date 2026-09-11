class_name MineOverview
extends Control

const Colors = preload("res://src/industry/ui/industry_theme.gd")
var _depth := 0
var _drill_level := 1
var _job: Dictionary = {}

func _ready() -> void:
    custom_minimum_size = Vector2(240, 260)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func set_progress(depth: int, drill_level: int, job: Dictionary) -> void:
    _depth = depth
    _drill_level = drill_level
    _job = job.duplicate()
    queue_redraw()

func _draw() -> void:
    var width := size.x
    var height := size.y
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(Vector2.ZERO, size), Color("0c1925"))
    var surface := 48.0
    var layer_height := (height - surface) / 4.0
    var shades := [Color("35444c"), Color("3e4548"), Color("35414b"), Color("263542")]
    for layer in range(4):
        var top := surface + layer * layer_height
        var polygon := PackedVector2Array()
        for point in range(9):
            var x := width * point / 8.0
            polygon.append(Vector2(x, top + sin(point * 1.7 + layer * 2.1) * 6.0))
        polygon.append(Vector2(width, height))
        polygon.append(Vector2(0, height))
        draw_colored_polygon(polygon, shades[layer])
    # Fixed geometric seams keep the geology stable as the HUD refreshes.
    for index in range(32):
        var x := fmod(index * 73.0 + 17.0, width - 22.0) + 11.0
        var y := surface + 18.0 + fmod(index * 47.0, height - surface - 30.0)
        var ore_color := Colors.COPPER if index % 3 == 0 else Color("75909a")
        if index % 3 == 1:
            ore_color = Color("14202a")
        draw_line(Vector2(x, y), Vector2(x + 8, y - 4), ore_color, 3.0)
    var shaft := width * 0.50
    var display_depth := maxf(90.0, (floorf(float(_depth) / 30.0) + 1.0) * 30.0)
    var usable_height := height - surface - 55.0
    var actual_y := surface + 20.0 + float(_depth) / display_depth * usable_height
    var tip := actual_y
    if not _job.is_empty():
        var progress := 1.0 - float(_job["remaining"]) / float(_job["duration"])
        tip += progress * (float(_job["target_depth"]) - _depth) / display_depth * usable_height
    draw_rect(Rect2(shaft - 19, surface, 38, maxf(26, tip - surface + 15)), Color("09121b"))
    for y in range(int(surface), int(tip + 10), 18):
        draw_line(Vector2(shaft - 16, y), Vector2(shaft + 16, y), Color("587181"), 2)
        draw_line(Vector2(shaft - 15, y), Vector2(shaft - 15, y + 18), Color("80909a"), 2)
        draw_circle(Vector2(shaft + 12, y + 5), 2, Colors.ACCENT)
    for horizon in range(1, 4):
        var horizon_depth := display_depth * horizon / 3.0
        var y := surface + 20.0 + horizon_depth / display_depth * usable_height
        if horizon_depth <= _depth:
            draw_rect(Rect2(shaft - 47, y, 94, 5), Color("70828a"))
            draw_line(Vector2(shaft - 44, y + 5), Vector2(shaft - 20, y + 20), Color("506571"), 2)
            draw_circle(Vector2(shaft + 42, y - 4), 3, Colors.ACCENT)
        draw_line(Vector2(width - 60, y), Vector2(width - 12, y), Color("7c939d"), 1)
        draw_string(font, Vector2(width - 59, y - 5), "%d m" % int(horizon_depth), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Colors.MUTED)
    # Surface gantry, headframe and hoist.
    draw_line(Vector2(12, surface), Vector2(width - 12, surface), Colors.ACCENT, 2)
    draw_rect(Rect2(shaft - 50, surface - 15, 28, 15), Color("768c96"))
    draw_rect(Rect2(shaft - 44, surface - 11, 8, 5), Colors.ACCENT)
    draw_line(Vector2(shaft - 20, surface), Vector2(shaft - 12, 12), Colors.COPPER, 4)
    draw_line(Vector2(shaft + 20, surface), Vector2(shaft + 12, 12), Colors.COPPER, 4)
    draw_line(Vector2(shaft - 12, 12), Vector2(shaft + 12, 12), Colors.COPPER, 4)
    draw_circle(Vector2(shaft, 17), 7, Color("94acb4"))
    draw_line(Vector2(shaft, 24), Vector2(shaft, tip), Colors.COPPER, 1)
    draw_rect(Rect2(shaft - 10, tip - 4, 20, 14), Colors.COPPER)
    draw_colored_polygon(PackedVector2Array([Vector2(shaft - 10, tip + 10), Vector2(shaft + 10, tip + 10), Vector2(shaft, tip + 19)]), Colors.ACCENT)
    draw_line(Vector2(8, actual_y), Vector2(shaft - 24, actual_y), Colors.ACCENT, 1)
    draw_string(font, Vector2(10, actual_y - 6), "−%d m" % _depth, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Colors.ACCENT)
    draw_string(font, Vector2(12, height - 12), "COUPE DU SOUS-SOL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Colors.MUTED)
    draw_string(font, Vector2(width - 66, 22), "F · %02d" % _drill_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Colors.COPPER)

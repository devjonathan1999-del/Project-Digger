class_name MineWorld
extends Control

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")

signal selection_changed(kind: String, id: String)

const PIXELS_PER_METER := 7.0
const SURFACE_Y := 72.0

var min_zoom := 0.75
var max_zoom := 1.15
var zoom := 1.0
var scroll_depth := 0.0
var velocity := 0.0

var session
var _dragging := false
var _last_pointer_y := 0.0
var _targets: Array[Control] = []

func _ready() -> void:
    name = "MineWorld"
    custom_minimum_size = Vector2(360, 500)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    resized.connect(refresh)
    queue_redraw()

func bind_session(value) -> void:
    session = value
    if session != null and not session.changed.is_connected(refresh):
        session.changed.connect(refresh)
    refresh()

func focus_depth(target_depth: int) -> void:
    var visible_span := maxf(20.0, (size.y - SURFACE_Y) / maxf(PIXELS_PER_METER * zoom, 0.01))
    scroll_depth = clampf(float(target_depth) - visible_span * 0.42, 0.0, _max_scroll_depth())
    velocity = 0.0
    refresh()

func refresh() -> void:
    if not is_inside_tree():
        queue_redraw()
        return
    _rebuild_targets()
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
            zoom = clampf(zoom + 0.08, min_zoom, max_zoom)
            refresh()
            accept_event()
        elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
            zoom = clampf(zoom - 0.08, min_zoom, max_zoom)
            refresh()
            accept_event()
        elif button.button_index == MOUSE_BUTTON_LEFT:
            _dragging = button.pressed
            _last_pointer_y = button.position.y
            if not button.pressed:
                velocity = 0.0
    elif event is InputEventMouseMotion and _dragging:
        var motion := event as InputEventMouseMotion
        var delta_y := motion.position.y - _last_pointer_y
        _last_pointer_y = motion.position.y
        scroll_depth = clampf(scroll_depth - delta_y / maxf(PIXELS_PER_METER * zoom, 0.01), 0.0, _max_scroll_depth())
        velocity = -delta_y
        refresh()
        accept_event()
    elif event is InputEventMagnifyGesture:
        var gesture := event as InputEventMagnifyGesture
        zoom = clampf(zoom * gesture.factor, min_zoom, max_zoom)
        refresh()
        accept_event()

func _draw() -> void:
    var width := size.x
    var height := size.y
    draw_rect(Rect2(Vector2.ZERO, size), Color("101923"))

    _draw_zone(0.0, 60.0, Color("343b40"))
    _draw_zone(60.0, 90.0, Color("252f38"))
    _draw_zone(90.0, 150.0, Color("1b2933"))
    _draw_zone(150.0, maxf(220.0, scroll_depth + 120.0), Color("14212b"))

    var surface_y := _depth_to_y(0.0)
    if surface_y > -80.0 and surface_y < height + 80.0:
        draw_rect(Rect2(0, surface_y - 56, width, 56), Color("17242d"))
        draw_line(Vector2(0, surface_y), Vector2(width, surface_y), Style.ACCENT, 2.0)
        _draw_surface_modules(surface_y)

    var max_horizon := maxi(180, session.game.depth + 60 if session != null else 180)
    for horizon in range(30, max_horizon + 1, 30):
        var y := _depth_to_y(float(horizon))
        if y < -20.0 or y > height + 20.0:
            continue
        var line_color := Color("54707d")
        if horizon >= 90:
            line_color = Color("39aab7")
        draw_line(Vector2(14, y), Vector2(width - 14, y), line_color, 1.0)
        draw_string(ThemeDB.fallback_font, Vector2(18, y - 7), "−%d m" % horizon, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Style.MUTED)

    var shaft_x := width * 0.5
    var shaft_top := _depth_to_y(0.0)
    var shaft_bottom_depth := float(session.game.depth if session != null else 0) + 8.0
    var shaft_bottom := _depth_to_y(shaft_bottom_depth)
    draw_rect(Rect2(shaft_x - 15, minf(shaft_top, shaft_bottom), 30, absf(shaft_bottom - shaft_top)), Color("0a1118"))
    draw_line(Vector2(shaft_x - 10, shaft_top), Vector2(shaft_x - 10, shaft_bottom), Color("6a7c84"), 2.0)
    draw_line(Vector2(shaft_x + 10, shaft_top), Vector2(shaft_x + 10, shaft_bottom), Color("6a7c84"), 2.0)

    if session != null and session.game.depth >= 90:
        _draw_crystal_signatures()

func _draw_zone(from_depth: float, to_depth: float, color: Color) -> void:
    var y1 := _depth_to_y(from_depth)
    var y2 := _depth_to_y(to_depth)
    var top := minf(y1, y2)
    var bottom := maxf(y1, y2)
    if bottom < 0.0 or top > size.y:
        return
    draw_rect(Rect2(0, top, size.x, bottom - top), color)

func _draw_surface_modules(surface_y: float) -> void:
    var width := size.x
    var base_y := surface_y - 10.0
    var module_w := minf(74.0, width * 0.16)
    var gap := 12.0
    var total := module_w * 4.0 + gap * 3.0
    var start_x := maxf(10.0, (width - total) * 0.5)
    var colors := [Color("8d6744"), Color("af7d4c"), Color("71818a"), Color("526b75")]
    for index in range(4):
        var x: float = start_x + index * (module_w + gap)
        draw_rect(Rect2(x, base_y - 30.0, module_w, 30.0), colors[index])
        draw_rect(Rect2(x + 7.0, base_y - 22.0, module_w - 14.0, 7.0), Color("d0a06a"))

func _draw_crystal_signatures() -> void:
    var widths: Array[float] = [0.18, 0.78, 0.28, 0.70]
    var depths: Array[float] = [98.0, 112.0, 132.0, 154.0]
    for index in range(depths.size()):
        var y := _depth_to_y(depths[index])
        if y < 0.0 or y > size.y:
            continue
        var x: float = size.x * widths[index]
        var points := PackedVector2Array([
            Vector2(x, y - 8),
            Vector2(x + 7, y + 5),
            Vector2(x, y + 14),
            Vector2(x - 7, y + 5),
        ])
        draw_colored_polygon(points, Color("44d9d2"))

func _rebuild_targets() -> void:
    for target in _targets:
        if is_instance_valid(target):
            target.queue_free()
    _targets.clear()
    if session == null:
        return

    var mine_ids: Array = Catalog.MINES.keys()
    var ratios: Array[float] = [0.18, 0.50, 0.82]
    for index in range(mine_ids.size()):
        var id := str(mine_ids[index])
        var x_ratio: float = ratios[index % 3]
        _add_target("Mine_" + id, "mine", id, Vector2(size.x * x_ratio, _depth_to_y(12.0)), Catalog.RESOURCES[id]["label"])

    _add_target("Drill", "drill", "drill", Vector2(size.x * 0.5, _depth_to_y(float(session.game.depth) + 7.0)), "Foreuse")

    var discovery_ids: Array = session.game.discoveries.keys()
    discovery_ids.sort()
    for discovery_id in discovery_ids:
        var discovery: Dictionary = session.game.discoveries[discovery_id]
        var slot := int(discovery.get("slot", 0))
        var x: float = size.x * (0.24 if slot % 2 == 0 else 0.76)
        var label := str(discovery.get("hint", "Découverte"))
        _add_target("Discovery_" + str(discovery_id).replace(":", "_"), "discovery", str(discovery_id), Vector2(x, _depth_to_y(float(discovery.get("depth", 0)))), label)

    var site_ids: Array = session.game.permanent_sites.keys()
    site_ids.sort()
    for site_id in site_ids:
        var site: Dictionary = session.game.permanent_sites[site_id]
        var x: float = size.x * 0.76
        _add_target("Site_" + str(site_id).replace(":", "_"), "site", str(site_id), Vector2(x, _depth_to_y(float(site.get("depth", 0)))), "Site")

func _add_target(node_name: String, kind: String, id: String, center: Vector2, title: String) -> void:
    var button := Button.new()
    button.name = node_name
    button.text = title
    button.tooltip_text = title
    button.custom_minimum_size = Vector2(112, 34)
    button.size = Vector2(112, 34)
    button.position = Vector2(clampf(center.x - 56.0, 4.0, maxf(4.0, size.x - 116.0)), center.y - 17.0)
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    button.pressed.connect(_emit_selection.bind(kind, id))
    add_child(button)
    _targets.append(button)

func _emit_selection(kind: String, id: String) -> void:
    selection_changed.emit(kind, id)

func _depth_to_y(depth_value: float) -> float:
    return SURFACE_Y + (depth_value - scroll_depth) * PIXELS_PER_METER * zoom

func _max_scroll_depth() -> float:
    var deepest := 180.0
    if session != null:
        deepest = maxf(deepest, float(session.game.depth) + 60.0)
        for discovery in session.game.discoveries.values():
            deepest = maxf(deepest, float(discovery.get("depth", 0)) + 40.0)
        for site in session.game.permanent_sites.values():
            deepest = maxf(deepest, float(site.get("depth", 0)) + 40.0)
    return maxf(0.0, deepest - 35.0)

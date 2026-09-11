class_name MineWorld
extends Control

const Catalog = preload("res://src/industry/industry_catalog.gd")
const Style = preload("res://src/industry/ui/industry_theme.gd")

signal selection_changed(kind: String, id: String)

const PIXELS_PER_METER := 7.0
const SURFACE_Y := 72.0
const WORKER_DEPTHS: Array[float] = [8.0, 24.0, 42.0, 70.0]
const WORKER_X: Array[float] = [0.12, 0.34, 0.66, 0.86]

var min_zoom := 0.75
var max_zoom := 1.15
var zoom := 1.0
var scroll_depth := 0.0
var velocity := 0.0
var animation_phase := 0.0
var deep_zone_visible := false

var session
var _dragging := false
var _last_pointer_y := 0.0
var _targets: Array[Control] = []

var _decor_root: Control
var _elevator: ColorRect
var _conveyor_left: ColorRect
var _conveyor_right: ColorRect
var _mine_cart: ColorRect
var _workers: Array[Control] = []
var _mine_activity: Dictionary = {}
var _drill_activity: ColorRect
var _crystal_activity: Dictionary = {}

func _ready() -> void:
    name = "MineWorld"
    custom_minimum_size = Vector2(360, 500)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    _build_static_decor()
    resized.connect(refresh)
    set_process(true)
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
    _sync_decor_state()
    _update_decor_positions()
    _update_animation_state()
    queue_redraw()

func _process(delta: float) -> void:
    if not is_finite(delta) or delta <= 0.0:
        return
    animation_phase = fmod(animation_phase + delta, 1000.0)
    if is_inside_tree():
        _update_decor_positions()
        _update_animation_state()
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

    _draw_zone(0.0, 60.0, Style.ROCK_SHALLOW)
    _draw_zone(60.0, 90.0, Style.ROCK_DENSE)
    _draw_zone(90.0, 150.0, Style.ROCK_CRYSTAL)
    _draw_zone(150.0, maxf(220.0, scroll_depth + 120.0), Style.ROCK_DEEP)
    _draw_strata()

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
        var line_color := Style.STEEL_DARK
        if horizon >= 90:
            line_color = Style.CRYSTAL_CYAN
        draw_line(Vector2(14, y), Vector2(width - 14, y), line_color, 1.0)
        draw_string(ThemeDB.fallback_font, Vector2(18, y - 7), "−%d m" % horizon, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Style.MUTED)

    var shaft_x := width * 0.5
    var shaft_top := _depth_to_y(0.0)
    var shaft_bottom_depth := float(session.game.depth if session != null else 0) + 8.0
    var shaft_bottom := _depth_to_y(shaft_bottom_depth)
    draw_rect(Rect2(shaft_x - 15, minf(shaft_top, shaft_bottom), 30, absf(shaft_bottom - shaft_top)), Color("0a1118"))
    draw_line(Vector2(shaft_x - 10, shaft_top), Vector2(shaft_x - 10, shaft_bottom), Style.STEEL, 2.0)
    draw_line(Vector2(shaft_x + 10, shaft_top), Vector2(shaft_x + 10, shaft_bottom), Style.STEEL, 2.0)

    if session != null and session.game.depth >= 90:
        _draw_crystal_signatures()
        _draw_anomaly_halos()
    _draw_deep_features()

func _draw_zone(from_depth: float, to_depth: float, color: Color) -> void:
    var y1 := _depth_to_y(from_depth)
    var y2 := _depth_to_y(to_depth)
    var top := minf(y1, y2)
    var bottom := maxf(y1, y2)
    if bottom < 0.0 or top > size.y:
        return
    draw_rect(Rect2(0, top, size.x, bottom - top), color)

func _draw_strata() -> void:
    var first_depth := floori(scroll_depth / 12.0) * 12
    var last_depth := ceili(scroll_depth + size.y / maxf(PIXELS_PER_METER * zoom, 0.01)) + 12
    for depth_value in range(first_depth, last_depth + 1, 12):
        if depth_value < 0:
            continue
        var y := _depth_to_y(float(depth_value))
        if y < 0.0 or y > size.y:
            continue
        var alpha := 0.08 if depth_value < 90 else 0.12
        draw_line(Vector2(0, y), Vector2(size.x, y + sin(float(depth_value)) * 3.0), Color(0.75, 0.82, 0.84, alpha), 1.0)

func _draw_surface_modules(surface_y: float) -> void:
    var width := size.x
    var base_y := surface_y - 10.0
    var module_w := minf(74.0, width * 0.16)
    var gap := 12.0
    var total := module_w * 4.0 + gap * 3.0
    var start_x := maxf(10.0, (width - total) * 0.5)
    var colors := [Color("8d6744"), Color("af7d4c"), Style.STEEL, Style.STEEL_DARK]
    for index in range(4):
        var x: float = start_x + index * (module_w + gap)
        draw_rect(Rect2(x, base_y - 30.0, module_w, 30.0), colors[index])
        draw_rect(Rect2(x + 7.0, base_y - 22.0, module_w - 14.0, 7.0), Style.INDUSTRIAL_AMBER)

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
        draw_colored_polygon(points, Style.CRYSTAL_CYAN)

func _draw_anomaly_halos() -> void:
    if session == null:
        return
    var pulse := 2.0 + sin(animation_phase * 3.2) * 2.0
    for discovery in session.game.discoveries.values():
        if str(discovery.get("type", "")) != "unstable_cavity":
            continue
        var slot := int(discovery.get("slot", 0))
        var x := size.x * (0.24 if slot % 2 == 0 else 0.76)
        var y := _depth_to_y(float(discovery.get("depth", 0)))
        if y < -40.0 or y > size.y + 40.0:
            continue
        var halo := Color(Style.ANOMALY_VIOLET.r, Style.ANOMALY_VIOLET.g, Style.ANOMALY_VIOLET.b, 0.13)
        draw_circle(Vector2(x, y), 22.0 + pulse, halo)
        draw_arc(Vector2(x, y), 16.0 + pulse, 0.0, TAU, 24, Style.ANOMALY_VIOLET, 1.5)

func _draw_deep_features() -> void:
    var y150 := _depth_to_y(150.0)
    deep_zone_visible = y150 >= -30.0 and y150 <= size.y + 30.0
    if not deep_zone_visible:
        return
    var glow := 0.45 + 0.2 * sin(animation_phase * 1.8)
    var color := Color(Style.DEEP_TURQUOISE.r, Style.DEEP_TURQUOISE.g, Style.DEEP_TURQUOISE.b, glow)
    var starts: Array[float] = [0.12, 0.32, 0.62, 0.84]
    for index in range(starts.size()):
        var x := size.x * starts[index]
        var y := y150 + float(index * 26)
        draw_line(Vector2(x, y), Vector2(x + 14.0, y + 18.0), color, 2.0)
        draw_line(Vector2(x + 14.0, y + 18.0), Vector2(x + 5.0, y + 34.0), color, 1.5)

func _build_static_decor() -> void:
    _decor_root = Control.new()
    _decor_root.name = "MineDecor"
    _decor_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_decor_root)
    _decor_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _elevator = _decor_rect("ElevatorVisual", Style.INDUSTRIAL_AMBER, Vector2(24, 20))
    _conveyor_left = _decor_rect("ConveyorLeft", Style.STEEL, Vector2(104, 6))
    _conveyor_right = _decor_rect("ConveyorRight", Style.STEEL, Vector2(104, 6))
    _mine_cart = _decor_rect("MineCart", Style.COPPER, Vector2(30, 15))

    for index in range(4):
        var worker := _decor_rect("Worker_%d" % index, Style.WORKER_LIGHT, Vector2(6, 13))
        _workers.append(worker)

    var mine_ids: Array = Catalog.MINES.keys()
    for id in mine_ids:
        var marker := _decor_rect("MineActivity_" + str(id), Style.INDUSTRIAL_AMBER, Vector2(10, 10))
        _mine_activity[str(id)] = marker

    _drill_activity = _decor_rect("DrillActivity", Style.ACCENT, Vector2(16, 16))
    _drill_activity.visible = false

func _decor_rect(node_name: String, color: Color, dimensions: Vector2) -> ColorRect:
    var rect := ColorRect.new()
    rect.name = node_name
    rect.color = color
    rect.size = dimensions
    rect.custom_minimum_size = dimensions
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _decor_root.add_child(rect)
    return rect

func _sync_decor_state() -> void:
    if _decor_root == null:
        return
    _decor_root.size = size
    if session == null:
        _drill_activity.visible = false
        return

    for marker in _mine_activity.values():
        var mine_marker := marker as Control
        mine_marker.visible = true

    _drill_activity.visible = session.game.jobs.has("drill")
    _sync_crystal_activity()

func _sync_crystal_activity() -> void:
    var seen: Dictionary = {}
    for site_id in session.game.permanent_sites:
        var site: Dictionary = session.game.permanent_sites[site_id]
        if str(site.get("type", "")) != "crystal_cavern":
            continue
        var id := str(site_id)
        seen[id] = true
        var marker: ColorRect
        if _crystal_activity.has(id) and is_instance_valid(_crystal_activity[id]):
            marker = _crystal_activity[id] as ColorRect
        else:
            marker = _decor_rect("CrystalActivity_" + id.replace(":", "_"), Style.CRYSTAL_CYAN, Vector2(18, 18))
            _crystal_activity[id] = marker
        var active: bool = bool(site.get("active", false))
        marker.set_meta("active", active)
        marker.modulate = Color(1, 1, 1, 0.88 if active else 0.28)
        marker.visible = true

    var existing_ids: Array = _crystal_activity.keys()
    for id_value in existing_ids:
        var id := str(id_value)
        if seen.has(id):
            continue
        var stale := _crystal_activity[id] as Control
        if is_instance_valid(stale):
            stale.free()
        _crystal_activity.erase(id)

func _update_decor_positions() -> void:
    if _decor_root == null:
        return
    _decor_root.size = size
    if session == null:
        return

    var shaft_x := size.x * 0.5
    var surface_y := _depth_to_y(0.0)
    var bottom_y := _depth_to_y(float(session.game.depth) + 7.0)
    var travel_top := minf(surface_y, bottom_y)
    var travel_bottom := maxf(surface_y, bottom_y)
    var elevator_range := maxf(0.0, travel_bottom - travel_top - _elevator.size.y)
    var elevator_t := (sin(animation_phase * 1.35) + 1.0) * 0.5
    _elevator.position = Vector2(shaft_x - _elevator.size.x * 0.5, travel_top + elevator_range * elevator_t)
    _elevator.visible = _rect_near_view(_elevator.position, _elevator.size)

    var conveyor_shift := sin(animation_phase * 2.1) * 5.0
    var left_y := _depth_to_y(18.0)
    var right_y := _depth_to_y(42.0)
    _conveyor_left.position = Vector2(size.x * 0.08 + conveyor_shift, left_y)
    _conveyor_right.position = Vector2(size.x * 0.66 - conveyor_shift, right_y)
    _conveyor_left.visible = _rect_near_view(_conveyor_left.position, _conveyor_left.size)
    _conveyor_right.visible = _rect_near_view(_conveyor_right.position, _conveyor_right.size)

    var cart_y := _depth_to_y(30.0)
    var cart_span := maxf(30.0, size.x * 0.28)
    var cart_x := size.x * 0.18 + ((sin(animation_phase * 1.7) + 1.0) * 0.5) * cart_span
    _mine_cart.position = Vector2(cart_x, cart_y - 14.0)
    _mine_cart.visible = _rect_near_view(_mine_cart.position, _mine_cart.size)

    for index in range(_workers.size()):
        var worker := _workers[index]
        var worker_y := _depth_to_y(WORKER_DEPTHS[index]) + sin(animation_phase * 2.4 + float(index)) * 2.0
        var worker_x := size.x * WORKER_X[index]
        worker.position = Vector2(worker_x, worker_y - worker.size.y)
        worker.visible = _rect_near_view(worker.position, worker.size)

    var ratios: Array[float] = [0.18, 0.50, 0.82]
    var mine_ids: Array = Catalog.MINES.keys()
    for index in range(mine_ids.size()):
        var id := str(mine_ids[index])
        var marker := _mine_activity[id] as Control
        marker.position = Vector2(size.x * ratios[index % ratios.size()] - 5.0, _depth_to_y(12.0) + 20.0)
        marker.visible = _rect_near_view(marker.position, marker.size)

    _drill_activity.position = Vector2(shaft_x - 8.0, _depth_to_y(float(session.game.depth) + 7.0) + 18.0)
    if session.game.jobs.has("drill"):
        _drill_activity.visible = _rect_near_view(_drill_activity.position, _drill_activity.size)
    else:
        _drill_activity.visible = false

    for site_id in _crystal_activity:
        var site: Dictionary = session.game.permanent_sites.get(site_id, {})
        if site.is_empty():
            continue
        var marker := _crystal_activity[site_id] as Control
        marker.position = Vector2(size.x * 0.76 - 9.0, _depth_to_y(float(site.get("depth", 0))) + 20.0)
        marker.visible = _rect_near_view(marker.position, marker.size)

    var y150 := _depth_to_y(150.0)
    deep_zone_visible = y150 >= -30.0 and y150 <= size.y + 30.0

func _update_animation_state() -> void:
    if _decor_root == null:
        return
    var mine_pulse := 0.60 + 0.30 * ((sin(animation_phase * 3.0) + 1.0) * 0.5)
    for marker in _mine_activity.values():
        var mine_marker := marker as CanvasItem
        mine_marker.modulate = Color(1, 1, 1, mine_pulse)

    if _drill_activity != null and _drill_activity.visible:
        var drill_pulse := 0.62 + 0.38 * ((sin(animation_phase * 5.2) + 1.0) * 0.5)
        _drill_activity.modulate = Color(1, 1, 1, drill_pulse)

    if _elevator != null:
        _elevator.modulate = Color(1, 1, 1, 0.82 + 0.18 * ((sin(animation_phase * 2.0) + 1.0) * 0.5))

    for site_id in _crystal_activity:
        var marker := _crystal_activity[site_id] as CanvasItem
        var active: bool = bool(marker.get_meta("active", false))
        if active:
            var crystal_pulse := 0.70 + 0.30 * ((sin(animation_phase * 3.6) + 1.0) * 0.5)
            marker.modulate = Color(1, 1, 1, crystal_pulse)
        else:
            marker.modulate = Color(1, 1, 1, 0.28)

func _rect_near_view(position_value: Vector2, dimensions: Vector2) -> bool:
    return position_value.x + dimensions.x >= -8.0 and position_value.x <= size.x + 8.0 and position_value.y + dimensions.y >= -20.0 and position_value.y <= size.y + 20.0

func _rebuild_targets() -> void:
    for target in _targets:
        if is_instance_valid(target):
            target.free()
    _targets.clear()
    if session == null:
        return

    var mine_ids: Array = Catalog.MINES.keys()
    var ratios: Array[float] = [0.18, 0.50, 0.82]
    for index in range(mine_ids.size()):
        var id := str(mine_ids[index])
        var x_ratio: float = ratios[index % 3]
        _add_target("Mine_" + id, "mine", id, Vector2(size.x * x_ratio, _depth_to_y(12.0)), Catalog.RESOURCES[id]["label"])

    var drill_center := Vector2(size.x * 0.5, _depth_to_y(float(session.game.depth) + 7.0))
    _add_target("Drill", "drill", "drill", drill_center, "Foreuse")
    if session.game.jobs.has("drill"):
        _add_timer("Timer_Drill", session.game.jobs["drill"], drill_center + Vector2(0, 38))

    var discovery_ids: Array = session.game.discoveries.keys()
    discovery_ids.sort()
    for discovery_id in discovery_ids:
        var discovery: Dictionary = session.game.discoveries[discovery_id]
        var slot := int(discovery.get("slot", 0))
        var x: float = size.x * (0.24 if slot % 2 == 0 else 0.76)
        var center := Vector2(x, _depth_to_y(float(discovery.get("depth", 0))))
        var label := str(discovery.get("hint", "Découverte"))
        _add_target("Discovery_" + str(discovery_id).replace(":", "_"), "discovery", str(discovery_id), center, label)
        if session.game.explorations.has(discovery_id):
            _add_timer("Timer_Exploration_" + str(discovery_id).replace(":", "_"), session.game.explorations[discovery_id], center + Vector2(0, 38))

    var site_ids: Array = session.game.permanent_sites.keys()
    site_ids.sort()
    for site_id in site_ids:
        var site: Dictionary = session.game.permanent_sites[site_id]
        var x: float = size.x * 0.76
        var center := Vector2(x, _depth_to_y(float(site.get("depth", 0))))
        _add_target("Site_" + str(site_id).replace(":", "_"), "site", str(site_id), center, "Site")
        if bool(site.get("active", false)):
            _add_site_status("Status_Site_" + str(site_id).replace(":", "_"), site, center + Vector2(0, 38))

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

func _add_timer(node_name: String, job: Dictionary, center: Vector2) -> void:
    var container := VBoxContainer.new()
    container.name = node_name
    container.custom_minimum_size = Vector2(112, 28)
    container.size = Vector2(112, 32)
    container.position = Vector2(clampf(center.x - 56.0, 4.0, maxf(4.0, size.x - 116.0)), center.y - 14.0)
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var label := Label.new()
    label.text = _duration(float(job.get("remaining", 0.0)))
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 11)
    label.add_theme_color_override("font_color", Style.ACCENT)
    container.add_child(label)
    var progress := ProgressBar.new()
    progress.custom_minimum_size.y = 5
    progress.show_percentage = false
    var duration := maxf(float(job.get("duration", 1.0)), 0.001)
    progress.value = 100.0 * (1.0 - float(job.get("remaining", 0.0)) / duration)
    container.add_child(progress)
    add_child(container)
    _targets.append(container)

func _add_site_status(node_name: String, site: Dictionary, center: Vector2) -> void:
    var label := Label.new()
    label.name = node_name
    label.text = "ACTIF · %.2f/min" % (float(site.get("rate", 0.0)) * 60.0)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 11)
    label.add_theme_color_override("font_color", Style.CRYSTAL_CYAN)
    label.custom_minimum_size = Vector2(112, 22)
    label.size = Vector2(112, 22)
    label.position = Vector2(clampf(center.x - 56.0, 4.0, maxf(4.0, size.x - 116.0)), center.y - 11.0)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(label)
    _targets.append(label)

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

func _duration(seconds: float) -> String:
    var rounded := ceili(maxf(0.0, seconds))
    return "%d:%02d" % [rounded / 60, rounded % 60]

class_name MineFinalModuleRenderer
extends "res://src/industry/ui/mine_module_renderer.gd"

const SURFACE_WIDE_MIN_GROUND_Y := 118.0
const SURFACE_NARROW_MIN_GROUND_Y := 104.0
const RELIEF_DEPTHS := [22.0, 45.0, 75.0, 105.0, 135.0, 165.0, 195.0]

func set_scene_state(state: Dictionary) -> void:
    super.set_scene_state(state)
    var viewport_size: Vector2 = state.get("viewport_size", size)
    if viewport_size.x <= 0.0:
        viewport_size = Vector2(1280.0, 800.0)
    var narrow := viewport_size.x < 800.0
    var center_level := int(state.get("center_level", 1))
    var total_depth := int(state.get("depth", 0))
    var surface_profile: Dictionary = Layout.surface_profile(center_level)
    var modules: Array = surface_profile.get("modules", [])
    var actual_ground_y := _depth_to_y(0.0)
    var visual_ground_y := _surface_visual_ground_y(actual_ground_y, narrow)
    var rects := _surface_asset_rects(viewport_size.x, visual_ground_y, modules, narrow)
    _metrics["narrow_mode"] = narrow
    _metrics["shaft_center_x"] = viewport_size.x * 0.5
    _metrics["surface_bounds_ok"] = _rects_within_width(rects, viewport_size.x)
    _metrics["surface_vertical_bounds_ok"] = _rects_within_height(rects, viewport_size.y)
    _metrics["surface_visual_ground_y"] = visual_ground_y
    _metrics["rock_relief_count"] = _relief_depth_count(total_depth)
    _metrics["decorative_detail_level"] = 1 if narrow else 2
    queue_redraw()

func _draw_final_geology() -> void:
    super._draw_final_geology()
    _draw_final_rock_relief()

func _draw_final_rock_relief() -> void:
    var total_depth := int(_state.get("depth", 0))
    var shaft_width := float(_metrics.get("shaft_width", 120.0))
    var shaft_left := size.x * 0.5 - shaft_width * 0.5
    var shaft_right := size.x * 0.5 + shaft_width * 0.5

    for index in range(RELIEF_DEPTHS.size()):
        var relief_depth := float(RELIEF_DEPTHS[index])
        if relief_depth > float(total_depth + 45):
            continue
        var y := _depth_to_y(relief_depth)
        if y < -80.0 or y > size.y + 80.0:
            continue

        var wobble := float((index * 19 + total_depth) % 17) - 8.0
        var left_start := 20.0 + float(index % 3) * 18.0
        var left_end := minf(shaft_left - 30.0, size.x * (0.30 + float(index % 2) * 0.06))
        var right_start := maxf(shaft_right + 30.0, size.x * (0.67 - float(index % 2) * 0.04))
        var right_end := size.x - 20.0 - float((index + 1) % 3) * 14.0

        if left_end - left_start > 90.0:
            _draw_rock_relief_mass(left_start, left_end, y + wobble, relief_depth, index, -1)
        if right_end - right_start > 90.0:
            _draw_rock_relief_mass(right_start, right_end, y - wobble * 0.65, relief_depth, index, 1)

func _draw_rock_relief_mass(x_start: float, x_end: float, y: float, relief_depth: float, index: int, side: int) -> void:
    var width := x_end - x_start
    var height := 28.0 + float((index + absi(side)) % 3) * 8.0
    var shoulder := height * 0.42
    var key_shift := float((index * 7 + absi(side) * 5) % 11) - 5.0
    var points := PackedVector2Array([
        Vector2(x_start, y + shoulder * 0.45),
        Vector2(x_start + width * 0.14, y - shoulder * 0.55 + key_shift),
        Vector2(x_start + width * 0.34, y - height * 0.50),
        Vector2(x_start + width * 0.57, y - shoulder * 0.38 - key_shift * 0.5),
        Vector2(x_start + width * 0.77, y - height * 0.34),
        Vector2(x_end, y + shoulder * 0.10),
        Vector2(x_end - width * 0.12, y + height * 0.50),
        Vector2(x_start + width * 0.58, y + height * 0.42),
        Vector2(x_start + width * 0.26, y + height * 0.54),
        Vector2(x_start, y + shoulder * 0.45),
    ])

    var mass_color := Color("202a2d")
    if relief_depth >= 90.0:
        mass_color = Color("17292d")
    draw_colored_polygon(points, mass_color)
    draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[5]]), Color(0.37, 0.40, 0.39, 0.42), 3.0, true)
    draw_line(Vector2(x_start + width * 0.08, y + height * 0.47), Vector2(x_end - width * 0.08, y + height * 0.43), Color(0.03, 0.05, 0.055, 0.82), 5.0)

    var boulder_color := Color("11191c")
    for boulder_index in range(3):
        var ratio := 0.24 + float(boulder_index) * 0.22
        var radius := 8.0 + float((index + boulder_index) % 3) * 3.0
        var boulder_y := y + height * (0.17 + float(boulder_index % 2) * 0.12)
        draw_circle(Vector2(lerpf(x_start, x_end, ratio), boulder_y), radius, boulder_color)
        draw_arc(Vector2(lerpf(x_start, x_end, ratio), boulder_y), radius, -2.8, -0.35, 12, Color(0.35, 0.36, 0.34, 0.28), 1.5)

    var seam_color := Color(0.58, 0.34, 0.20, 0.60)
    if relief_depth >= 90.0 and int(_state.get("depth", 0)) >= 90:
        seam_color = Color(0.16, 0.72, 0.74, 0.58)
    var seam_y := y - height * 0.08
    draw_polyline(PackedVector2Array([
        Vector2(x_start + width * 0.12, seam_y + 5.0),
        Vector2(x_start + width * 0.32, seam_y - 3.0),
        Vector2(x_start + width * 0.51, seam_y + 4.0),
        Vector2(x_start + width * 0.69, seam_y - 5.0),
        Vector2(x_start + width * 0.86, seam_y + 1.0),
    ]), seam_color, 2.0, true)

    if index % 2 == 0:
        var brace_x := x_start + width * (0.72 if side < 0 else 0.28)
        draw_line(Vector2(brace_x, y - height * 0.30), Vector2(brace_x, y + height * 0.34), Color("4e595b"), 3.0)
        draw_line(Vector2(brace_x - 10.0, y - height * 0.30), Vector2(brace_x + 10.0, y - height * 0.30), Color("87583b"), 3.0)

func _relief_depth_count(total_depth: int) -> int:
    var count := 0
    for relief_depth_value in RELIEF_DEPTHS:
        if float(relief_depth_value) <= float(total_depth + 45):
            count += 1
    return count

func _draw_surface_base() -> void:
    var actual_ground_y := _depth_to_y(0.0)
    if actual_ground_y < -140.0 or actual_ground_y > size.y + 140.0:
        return

    var center_level := int(_state.get("center_level", 1))
    var profile: Dictionary = Layout.surface_profile(center_level)
    var modules: Array = profile.get("modules", [])
    var narrow := size.x < 800.0
    var ground_y := _surface_visual_ground_y(actual_ground_y, narrow)
    var shaft_x := size.x * 0.5
    var apron_height := 88.0 if narrow else 102.0

    draw_rect(Rect2(0.0, ground_y - apron_height, size.x, apron_height), Color("101a20"))
    draw_rect(Rect2(0.0, ground_y - 12.0, size.x, 12.0), Color("252a2b"))
    draw_line(Vector2(0.0, ground_y), Vector2(size.x, ground_y), Color("a16c3f"), 4.0)
    draw_line(Vector2(0.0, ground_y - 5.0), Vector2(size.x, ground_y - 5.0), Color(0.18, 0.22, 0.23, 0.9), 2.0)

    if modules.has("headframe"):
        _draw_headframe(shaft_x, ground_y)

    var rects := _surface_asset_rects(size.x, ground_y, modules, narrow)
    for asset_id_value in rects:
        var asset_id := str(asset_id_value)
        var rect: Rect2 = rects[asset_id_value]
        _draw_asset(asset_id, rect)

    if modules.has("antenna"):
        _draw_antenna(size.x * (0.70 if narrow else 0.77), ground_y)
    if modules.has("pipe_network"):
        _draw_surface_utilities(ground_y, shaft_x)
    var light_count := int(profile.get("light_count", 4))
    if narrow:
        light_count = mini(light_count, 5)
    _draw_surface_lights(ground_y, light_count)

func _surface_visual_ground_y(actual_ground_y: float, narrow: bool) -> float:
    if actual_ground_y < 0.0:
        return actual_ground_y
    var minimum_ground_y := SURFACE_NARROW_MIN_GROUND_Y if narrow else SURFACE_WIDE_MIN_GROUND_Y
    return maxf(actual_ground_y, minimum_ground_y)

func _draw_resource_installations() -> void:
    if size.x >= 800.0:
        super._draw_resource_installations()
        return

    var y := _depth_to_y(12.0)
    if y >= -110.0 and y <= size.y + 110.0:
        _draw_narrow_resource("iron_module", Vector2(size.x * 0.17, y), Vector2(150.0, 78.0), Color("9f5b3c"), -1)
        _draw_narrow_resource("coal_module", Vector2(size.x * 0.37, y), Vector2(138.0, 76.0), Color("34383a"), 0)
        _draw_narrow_resource("copper_module", Vector2(size.x * 0.82, y), Vector2(150.0, 78.0), Color("b76d43"), 1)
    _draw_crystal_installation()

func _draw_narrow_resource(asset_id: String, center: Vector2, dimensions: Vector2, accent: Color, signature: int) -> void:
    var rect := Rect2(center - dimensions * 0.5, dimensions)
    _draw_asset(asset_id, rect)
    var floor_y := rect.end.y - 6.0
    draw_line(Vector2(rect.position.x + 8.0, floor_y), Vector2(rect.end.x - 8.0, floor_y), Color("606a6c"), 3.0)
    _draw_local_work_light(Vector2(rect.position.x + 14.0, rect.position.y + 9.0), Color("e9a050"))
    if signature < 0:
        draw_circle(Vector2(rect.end.x - 29.0, floor_y - 8.0), 10.0, accent)
        draw_circle(Vector2(rect.end.x - 15.0, floor_y - 6.0), 7.0, accent.lightened(0.10))
    elif signature == 0:
        draw_circle(Vector2(rect.position.x + 28.0, floor_y - 8.0), 11.0, Color("151718"))
        var fan_center := Vector2(rect.end.x - 24.0, rect.position.y + 23.0)
        draw_circle(fan_center, 11.0, Color("273034"))
        draw_arc(fan_center, 11.0, 0.0, TAU, 20, Color("7e8b8f"), 2.0)
    else:
        draw_line(Vector2(rect.position.x + 10.0, floor_y - 4.0), Vector2(rect.position.x + 55.0, floor_y - 17.0), accent, 4.0)
        draw_line(Vector2(rect.position.x + 55.0, floor_y - 17.0), Vector2(rect.position.x + 88.0, floor_y - 4.0), Color("5e9772"), 3.0)

func _surface_asset_rects(viewport_width: float, ground_y: float, modules: Array, narrow: bool) -> Dictionary:
    var rects: Dictionary = {}
    if narrow:
        if modules.has("workshop"):
            rects["surface_workshop"] = Rect2(10.0, ground_y - 77.0, 132.0, 71.0)
        if modules.has("silo"):
            rects["surface_silo"] = Rect2(146.0, ground_y - 79.0, 78.0, 73.0)
        if modules.has("ventilation"):
            rects["surface_ventilation"] = Rect2(viewport_width * 0.39, ground_y - 63.0, 86.0, 57.0)
        if modules.has("operations"):
            rects["surface_control"] = Rect2(viewport_width - 148.0, ground_y - 77.0, 138.0, 71.0)
        # Crane is tertiary clutter on narrow screens; the industrial identity
        # remains through the headframe, control room, silo and ventilation.
    else:
        if modules.has("workshop"):
            rects["surface_workshop"] = Rect2(viewport_width * 0.055, ground_y - 90.0, 190.0, 84.0)
        if modules.has("silo"):
            rects["surface_silo"] = Rect2(viewport_width * 0.235, ground_y - 98.0, 118.0, 92.0)
        if modules.has("operations"):
            rects["surface_control"] = Rect2(viewport_width * 0.645, ground_y - 90.0, 185.0, 84.0)
        if modules.has("ventilation"):
            rects["surface_ventilation"] = Rect2(viewport_width * 0.795, ground_y - 76.0, 124.0, 70.0)
        if modules.has("crane"):
            rects["surface_crane"] = Rect2(viewport_width * 0.865, ground_y - 108.0, 145.0, 102.0)
    return rects

func _rects_within_width(rects: Dictionary, viewport_width: float) -> bool:
    for rect_value in rects.values():
        var rect: Rect2 = rect_value
        if rect.position.x < -0.5 or rect.end.x > viewport_width + 0.5:
            return false
    return true

func _rects_within_height(rects: Dictionary, viewport_height: float) -> bool:
    for rect_value in rects.values():
        var rect: Rect2 = rect_value
        if rect.position.y < -0.5 or rect.end.y > viewport_height + 0.5:
            return false
    return true

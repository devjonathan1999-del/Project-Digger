class_name MineModuleRenderer
extends Control

const Layout = preload("res://src/industry/ui/mine_visual_layout.gd")
const Assets = preload("res://src/industry/ui/mine_v06_assets.gd")

const PIXELS_PER_METER := 7.0
const SURFACE_Y := 72.0

var _state: Dictionary = {}
var _metrics: Dictionary = {
    "surface_module_count": 0,
    "surface_feature_count": 0,
    "shaft_station_count": 0,
    "resource_installation_count": 0,
    "shaft_width": 0.0,
    "elevator_visible": false,
    "utility_line_count": 0,
    "iron_identity_score": 0,
    "coal_identity_score": 0,
    "copper_identity_score": 0,
    "crystal_identity_score": 0,
}

func _ready() -> void:
    name = "MineModuleRenderer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_scene_state(state: Dictionary) -> void:
    _state = state.duplicate(true)
    var center_level := int(_state.get("center_level", 1))
    var depth := int(_state.get("depth", 0))
    var viewport_size: Vector2 = _state.get("viewport_size", size)
    if viewport_size.x <= 0.0:
        viewport_size = Vector2(1280.0, 800.0)

    var surface_profile: Dictionary = Layout.surface_profile(center_level)
    var shaft_profile: Dictionary = Layout.shaft_profile(viewport_size.x, depth)
    var modules: Array = surface_profile.get("modules", [])
    var station_depths: Array = shaft_profile.get("station_depths", [])
    var crystal_visible := depth >= 90

    _metrics["surface_module_count"] = modules.size()
    _metrics["surface_feature_count"] = modules.size()
    _metrics["shaft_station_count"] = station_depths.size()
    _metrics["resource_installation_count"] = 3 + (1 if crystal_visible else 0)
    _metrics["shaft_width"] = float(shaft_profile.get("width", 0.0))
    _metrics["elevator_visible"] = bool(shaft_profile.get("elevator_visible", false))
    _metrics["utility_line_count"] = int(shaft_profile.get("utility_line_count", 0))
    _metrics["iron_identity_score"] = 6
    _metrics["coal_identity_score"] = 6
    _metrics["copper_identity_score"] = 6
    _metrics["crystal_identity_score"] = 5 if crystal_visible else 0
    queue_redraw()

func metrics() -> Dictionary:
    return _metrics.duplicate(true)

func _draw() -> void:
    if _state.is_empty():
        return
    _draw_surface_base()
    _draw_resource_installations()
    _draw_hero_shaft()

func _draw_surface_base() -> void:
    var ground_y := _depth_to_y(0.0)
    if ground_y < -140.0 or ground_y > size.y + 140.0:
        return

    var center_level := int(_state.get("center_level", 1))
    var profile: Dictionary = Layout.surface_profile(center_level)
    var modules: Array = profile.get("modules", [])
    var shaft_x := size.x * 0.5

    draw_rect(Rect2(0.0, ground_y - 102.0, size.x, 102.0), Color("101a20"))
    draw_rect(Rect2(0.0, ground_y - 12.0, size.x, 12.0), Color("252a2b"))
    draw_line(Vector2(0.0, ground_y), Vector2(size.x, ground_y), Color("a16c3f"), 4.0)
    draw_line(Vector2(0.0, ground_y - 5.0), Vector2(size.x, ground_y - 5.0), Color(0.18, 0.22, 0.23, 0.9), 2.0)

    if modules.has("headframe"):
        _draw_headframe(shaft_x, ground_y)
    if modules.has("workshop"):
        _draw_asset("surface_workshop", Rect2(size.x * 0.055, ground_y - 90.0, 190.0, 84.0))
    if modules.has("silo"):
        _draw_asset("surface_silo", Rect2(size.x * 0.235, ground_y - 98.0, 118.0, 92.0))
    if modules.has("operations"):
        _draw_asset("surface_control", Rect2(size.x * 0.645, ground_y - 90.0, 185.0, 84.0))
    if modules.has("ventilation"):
        _draw_asset("surface_ventilation", Rect2(size.x * 0.795, ground_y - 76.0, 124.0, 70.0))
    if modules.has("crane"):
        _draw_asset("surface_crane", Rect2(size.x * 0.865, ground_y - 108.0, 145.0, 102.0))
    if modules.has("antenna"):
        _draw_antenna(size.x * 0.77, ground_y)
    if modules.has("pipe_network"):
        _draw_surface_utilities(ground_y, shaft_x)
    _draw_surface_lights(ground_y, int(profile.get("light_count", 4)))

func _draw_resource_installations() -> void:
    var y := _depth_to_y(12.0)
    if y < -130.0 or y > size.y + 130.0:
        _draw_crystal_installation()
        return

    var iron_center := Vector2(size.x * 0.18, y)
    var coal_target := Vector2(size.x * 0.50, y)
    var copper_center := Vector2(size.x * 0.82, y)
    _draw_iron_installation(iron_center)
    _draw_coal_installation(coal_target)
    _draw_copper_installation(copper_center)
    _draw_crystal_installation()

func _draw_iron_installation(center: Vector2) -> void:
    var rect := Rect2(center.x - 118.0, center.y - 50.0, 236.0, 100.0)
    _draw_local_work_light(center + Vector2(-92.0, -42.0), Color("f0a451"))
    _draw_asset("iron_module", rect)
    var floor_y := rect.end.y - 9.0
    draw_line(Vector2(rect.position.x + 8.0, floor_y), Vector2(rect.end.x - 8.0, floor_y), Color("5d6668"), 5.0)
    draw_rect(Rect2(rect.position.x + 22.0, floor_y - 18.0, 84.0, 8.0), Color("6b4a37"))
    for index in range(5):
        var roller_x := rect.position.x + 30.0 + float(index) * 17.0
        draw_circle(Vector2(roller_x, floor_y - 8.0), 3.5, Color("9d714c"))
    draw_circle(Vector2(rect.position.x + 150.0, floor_y - 12.0), 15.0, Color("7a4934"))
    draw_circle(Vector2(rect.position.x + 168.0, floor_y - 9.0), 12.0, Color("98573d"))
    draw_circle(Vector2(rect.position.x + 184.0, floor_y - 7.0), 9.0, Color("b46745"))
    draw_rect(Rect2(rect.end.x - 54.0, floor_y - 27.0, 38.0, 20.0), Color("374349"))
    draw_circle(Vector2(rect.end.x - 45.0, floor_y - 5.0), 5.0, Color("11191d"))
    draw_circle(Vector2(rect.end.x - 22.0, floor_y - 5.0), 5.0, Color("11191d"))

func _draw_coal_installation(target: Vector2) -> void:
    var shaft_half := float(_metrics.get("shaft_width", 120.0)) * 0.5
    var width := 198.0
    var right_edge := target.x - shaft_half - 12.0
    var rect := Rect2(right_edge - width, target.y - 50.0, width, 100.0)
    _draw_asset("coal_module", rect)
    var floor_y := rect.end.y - 8.0
    draw_circle(Vector2(rect.position.x + 38.0, floor_y - 12.0), 18.0, Color("121416"))
    draw_circle(Vector2(rect.position.x + 59.0, floor_y - 9.0), 14.0, Color("1c1d1e"))
    draw_circle(Vector2(rect.position.x + 77.0, floor_y - 7.0), 10.0, Color("262626"))
    var fan_center := Vector2(rect.end.x - 42.0, rect.position.y + 27.0)
    draw_circle(fan_center, 16.0, Color("242d31"))
    draw_arc(fan_center, 16.0, 0.0, TAU, 28, Color("829095"), 3.0)
    for angle_value in [0.0, 1.5708, 3.1416, 4.7124]:
        var angle := float(angle_value)
        draw_line(fan_center, fan_center + Vector2(cos(angle), sin(angle)) * 12.0, Color("6d787c"), 3.0)
    draw_line(Vector2(rect.end.x - 24.0, target.y - 2.0), Vector2(target.x - shaft_half, target.y - 2.0), Color("67757a"), 8.0)
    for index in range(4):
        var haze_x := rect.position.x + 30.0 + float(index) * 35.0
        var haze_y := rect.position.y + 12.0 + float(index % 2) * 10.0
        draw_circle(Vector2(haze_x, haze_y), 15.0, Color(0.24, 0.22, 0.19, 0.10))
    _draw_local_work_light(Vector2(rect.end.x - 15.0, rect.position.y + 7.0), Color("d98d45"))

func _draw_copper_installation(center: Vector2) -> void:
    var rect := Rect2(center.x - 118.0, center.y - 50.0, 236.0, 100.0)
    _draw_asset("copper_module", rect)
    var seam_y := center.y + 33.0
    draw_line(Vector2(rect.position.x + 8.0, seam_y), Vector2(rect.position.x + 54.0, seam_y - 17.0), Color("c56e3f"), 5.0)
    draw_line(Vector2(rect.position.x + 54.0, seam_y - 17.0), Vector2(rect.position.x + 94.0, seam_y + 3.0), Color("55906d"), 4.0)
    draw_line(Vector2(rect.position.x + 94.0, seam_y + 3.0), Vector2(rect.position.x + 126.0, seam_y - 15.0), Color("d17e47"), 4.0)
    var drill_head := Vector2(rect.position.x + 48.0, center.y - 6.0)
    draw_colored_polygon(PackedVector2Array([
        drill_head + Vector2(-14.0, -9.0),
        drill_head + Vector2(10.0, 0.0),
        drill_head + Vector2(-14.0, 9.0),
    ]), Color("87979b"))
    draw_line(Vector2(rect.position.x + 62.0, center.y - 6.0), Vector2(rect.position.x + 126.0, center.y - 6.0), Color("a8643c"), 7.0)
    draw_line(Vector2(rect.position.x + 126.0, center.y - 6.0), Vector2(rect.position.x + 126.0, rect.end.y - 14.0), Color("70858a"), 5.0)
    draw_rect(Rect2(rect.end.x - 64.0, center.y - 20.0, 42.0, 46.0), Color("5c4b3d"))
    draw_rect(Rect2(rect.end.x - 58.0, center.y - 14.0, 30.0, 8.0), Color("a66a42"))
    _draw_local_work_light(Vector2(rect.position.x + 145.0, rect.position.y + 8.0), Color("f0a451"))

func _draw_crystal_installation() -> void:
    if int(_state.get("depth", 0)) < 90:
        return
    var crystal_depth := 90.0
    var sites: Dictionary = _state.get("permanent_sites", {})
    for site_value in sites.values():
        if site_value is Dictionary and str(site_value.get("type", "")) == "crystal_cavern":
            crystal_depth = float(site_value.get("depth", 90.0))
            break
    var center := Vector2(size.x * 0.76, _depth_to_y(crystal_depth))
    if center.y < -130.0 or center.y > size.y + 130.0:
        return
    var rect := Rect2(center.x - 120.0, center.y - 54.0, 240.0, 108.0)
    draw_circle(center, 74.0, Color(0.18, 0.82, 0.84, 0.045))
    _draw_asset("crystal_module", rect)
    for offset in [Vector2(-78.0, 24.0), Vector2(-55.0, 10.0), Vector2(78.0, 20.0)]:
        var base := center + offset
        draw_colored_polygon(PackedVector2Array([
            base + Vector2(-7.0, 12.0),
            base + Vector2(0.0, -18.0),
            base + Vector2(8.0, 12.0),
        ]), Color(0.25, 0.92, 0.94, 0.86))
    var scanner_x := center.x + 54.0
    draw_line(Vector2(scanner_x, center.y + 29.0), Vector2(scanner_x, center.y - 28.0), Color("708d91"), 4.0)
    draw_circle(Vector2(scanner_x, center.y - 30.0), 5.0, Color("48e1dc"))
    draw_arc(Vector2(scanner_x, center.y - 30.0), 19.0, -2.7, -0.45, 18, Color(0.28, 0.88, 0.88, 0.65), 2.0)
    draw_line(Vector2(center.x - 10.0, center.y - 28.0), Vector2(center.x - 10.0, center.y + 33.0), Color("7c8d91"), 7.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(center.x - 21.0, center.y + 34.0),
        Vector2(center.x - 10.0, center.y + 51.0),
        Vector2(center.x + 1.0, center.y + 34.0),
    ]), Color("48c9ca"))

func _draw_local_work_light(position_value: Vector2, color: Color) -> void:
    draw_circle(position_value, 4.0, color)
    draw_circle(position_value, 18.0, Color(color.r, color.g, color.b, 0.06))

func _draw_headframe(x: float, ground_y: float) -> void:
    var steel_dark := Color("303a3e")
    var steel := Color("6e7b80")
    var copper := Color("b86f3f")
    var amber := Color("f0a652")
    draw_rect(Rect2(x - 51.0, ground_y - 18.0, 102.0, 18.0), steel_dark)
    draw_line(Vector2(x - 45.0, ground_y - 5.0), Vector2(x - 27.0, ground_y - 92.0), steel, 8.0)
    draw_line(Vector2(x + 45.0, ground_y - 5.0), Vector2(x + 27.0, ground_y - 92.0), steel, 8.0)
    draw_line(Vector2(x - 31.0, ground_y - 88.0), Vector2(x + 31.0, ground_y - 88.0), steel, 7.0)
    draw_line(Vector2(x - 41.0, ground_y - 28.0), Vector2(x + 29.0, ground_y - 81.0), Color("4b565b"), 3.0)
    draw_line(Vector2(x + 41.0, ground_y - 28.0), Vector2(x - 29.0, ground_y - 81.0), Color("4b565b"), 3.0)
    draw_circle(Vector2(x, ground_y - 76.0), 15.0, Color("172126"))
    draw_arc(Vector2(x, ground_y - 76.0), 15.0, 0.0, TAU, 28, copper, 4.0)
    draw_line(Vector2(x, ground_y - 60.0), Vector2(x, ground_y + 7.0), copper, 3.0)
    draw_circle(Vector2(x - 38.0, ground_y - 15.0), 3.0, amber)
    draw_circle(Vector2(x + 38.0, ground_y - 15.0), 3.0, amber)

func _draw_surface_utilities(ground_y: float, shaft_x: float) -> void:
    var pipe := Color("965e3b")
    var steel := Color("536268")
    var utility_y := ground_y - 25.0
    draw_line(Vector2(size.x * 0.13, utility_y), Vector2(shaft_x - 55.0, utility_y), pipe, 6.0)
    draw_line(Vector2(shaft_x + 55.0, utility_y), Vector2(size.x * 0.83, utility_y), pipe, 6.0)
    draw_line(Vector2(size.x * 0.31, utility_y), Vector2(size.x * 0.31, ground_y - 8.0), steel, 4.0)
    draw_line(Vector2(size.x * 0.69, utility_y), Vector2(size.x * 0.69, ground_y - 8.0), steel, 4.0)
    for ratio_value in [0.18, 0.38, 0.62, 0.82]:
        var ratio := float(ratio_value)
        draw_circle(Vector2(size.x * ratio, utility_y), 4.0, Color("c17b43"))

func _draw_surface_lights(ground_y: float, count: int) -> void:
    var amount := maxi(2, count)
    for index in range(amount):
        var ratio := float(index + 1) / float(amount + 1)
        var x := size.x * ratio
        draw_line(Vector2(x, ground_y - 5.0), Vector2(x, ground_y - 20.0), Color("4f5a5f"), 2.0)
        draw_circle(Vector2(x, ground_y - 22.0), 3.2, Color("f0a552"))
        draw_circle(Vector2(x, ground_y - 22.0), 8.0, Color(0.95, 0.58, 0.24, 0.08))

func _draw_antenna(x: float, ground_y: float) -> void:
    draw_line(Vector2(x, ground_y - 5.0), Vector2(x, ground_y - 73.0), Color("758389"), 3.0)
    draw_circle(Vector2(x, ground_y - 72.0), 3.0, Color("4fd9d0"))
    draw_arc(Vector2(x, ground_y - 67.0), 13.0, -2.65, -0.50, 18, Color("47c7c1"), 2.0)

func _draw_hero_shaft() -> void:
    var depth := int(_state.get("depth", 0))
    if depth <= 0:
        return
    var viewport_size: Vector2 = _state.get("viewport_size", size)
    var profile: Dictionary = Layout.shaft_profile(viewport_size.x, depth)
    var shaft_width := float(profile.get("width", 120.0))
    var half_width := shaft_width * 0.5
    var center_x := size.x * 0.5
    var top_y := _depth_to_y(0.0)
    var bottom_y := _depth_to_y(float(depth) + 10.0)
    var top := minf(top_y, bottom_y)
    var bottom := maxf(top_y, bottom_y)
    var height := maxf(1.0, bottom - top)
    draw_rect(Rect2(center_x - half_width, top, shaft_width, height), Color("071015"))
    draw_rect(Rect2(center_x - half_width, top, 10.0, height), Color("323e43"))
    draw_rect(Rect2(center_x + half_width - 10.0, top, 10.0, height), Color("323e43"))
    var rail_left := center_x - half_width * 0.30
    var rail_right := center_x + half_width * 0.30
    var cable_left := center_x - half_width * 0.12
    var cable_right := center_x + half_width * 0.12
    draw_line(Vector2(rail_left, top), Vector2(rail_left, bottom), Color("78868b"), 4.0)
    draw_line(Vector2(rail_right, top), Vector2(rail_right, bottom), Color("78868b"), 4.0)
    draw_line(Vector2(cable_left, top), Vector2(cable_left, bottom), Color("ba7745"), 2.0)
    draw_line(Vector2(cable_right, top), Vector2(cable_right, bottom), Color("ba7745"), 2.0)
    draw_line(Vector2(center_x - half_width + 19.0, top), Vector2(center_x - half_width + 19.0, bottom), Color("526970"), 5.0)
    draw_line(Vector2(center_x + half_width - 19.0, top), Vector2(center_x + half_width - 19.0, bottom), Color("526970"), 5.0)
    _draw_shaft_bracing(center_x, half_width, top, bottom)
    _draw_shaft_stations(center_x, shaft_width, profile)
    _draw_elevator(center_x, half_width, top, bottom)

func _draw_shaft_bracing(center_x: float, half_width: float, top: float, bottom: float) -> void:
    var y := top + 34.0
    var flip := false
    while y < bottom:
        draw_line(Vector2(center_x - half_width + 10.0, y), Vector2(center_x + half_width - 10.0, y), Color("263338"), 2.0)
        if flip:
            draw_line(Vector2(center_x - half_width + 10.0, y - 26.0), Vector2(center_x + half_width - 10.0, y), Color("344247"), 2.0)
        else:
            draw_line(Vector2(center_x + half_width - 10.0, y - 26.0), Vector2(center_x - half_width + 10.0, y), Color("344247"), 2.0)
        flip = not flip
        y += 34.0

func _draw_shaft_stations(center_x: float, shaft_width: float, profile: Dictionary) -> void:
    var station_depths: Array = profile.get("station_depths", [])
    for station_depth in station_depths:
        var y := _depth_to_y(float(station_depth))
        if y < -70.0 or y > size.y + 70.0:
            continue
        var station_rect := Rect2(center_x - shaft_width * 0.70, y - 22.0, shaft_width * 1.40, 44.0)
        draw_rect(station_rect, Color(0.06, 0.09, 0.10, 0.94))
        _draw_asset("shaft_station", station_rect)
        draw_line(Vector2(station_rect.position.x, y + 18.0), Vector2(station_rect.end.x, y + 18.0), Color("718086"), 4.0)
        draw_circle(Vector2(center_x - shaft_width * 0.58, y - 15.0), 3.0, Color("eea052"))
        draw_circle(Vector2(center_x + shaft_width * 0.58, y - 15.0), 3.0, Color("eea052"))

func _draw_elevator(center_x: float, half_width: float, top: float, bottom: float) -> void:
    if not bool(_metrics.get("elevator_visible", false)):
        return
    var travel_top := top + 38.0
    var travel_bottom := maxf(travel_top, bottom - 38.0)
    var t := fposmod(float(_state.get("animation_phase", 0.0)) * 0.07, 1.0)
    var y := lerpf(travel_top, travel_bottom, t)
    var cage_w := maxf(34.0, half_width * 0.68)
    var cage_rect := Rect2(center_x - cage_w * 0.5, y - 22.0, cage_w, 44.0)
    draw_rect(cage_rect, Color("46545a"))
    draw_rect(Rect2(cage_rect.position + Vector2(5.0, 5.0), cage_rect.size - Vector2(10.0, 10.0)), Color("172229"))
    for offset_value in [-0.32, 0.0, 0.32]:
        var offset := float(offset_value)
        var x: float = center_x + cage_w * offset
        draw_line(Vector2(x, cage_rect.position.y + 4.0), Vector2(x, cage_rect.end.y - 4.0), Color("708087"), 2.0)
    draw_rect(Rect2(center_x - 13.0, y - 5.0, 26.0, 8.0), Color("e19a4e"))
    var counter_x := center_x + half_width - 28.0
    var counter_y := lerpf(travel_bottom, travel_top, t)
    draw_rect(Rect2(counter_x - 7.0, counter_y - 17.0, 14.0, 34.0), Color("80644c"))

func _draw_asset(id: String, rect: Rect2) -> void:
    var texture := Assets.texture_for(id)
    if texture != null:
        draw_texture_rect(texture, rect, false)
        return
    draw_rect(rect, Color("414d52"))
    draw_rect(Rect2(rect.position + Vector2(6.0, rect.size.y * 0.62), Vector2(rect.size.x - 12.0, 5.0)), Color("c47b43"))

func _depth_to_y(depth_value: float) -> float:
    return SURFACE_Y + (depth_value - float(_state.get("scroll_depth", 0.0))) * PIXELS_PER_METER * maxf(0.01, float(_state.get("zoom", 1.0)))

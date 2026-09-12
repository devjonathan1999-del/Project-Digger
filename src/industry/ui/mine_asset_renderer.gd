class_name MineAssetRenderer
extends "res://src/industry/ui/mine_final_module_renderer.gd"

const V07Assets = preload("res://src/industry/ui/mine_v07_assets.gd")
const STATION_DEPTHS: Array[int] = [30, 60, 90, 120, 150]

var _session
var _world: Control
var _v07_metrics: Dictionary = {}

func _ready() -> void:
    name = "MineAssetRenderer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    set_process(true)

func bind(session, world: Control) -> void:
    _session = session
    _world = world
    _sync_state()

func _process(_delta: float) -> void:
    if _session != null and _world != null:
        _sync_state()

func _sync_state() -> void:
    if _session == null or _world == null or _session.game == null:
        return
    var game = _session.game
    var viewport_size := size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        viewport_size = _world.size
    set_scene_state({
        "depth": game.depth,
        "center_level": game.center_level,
        "mine_levels": game.mine_levels.duplicate(true),
        "discoveries": game.discoveries.duplicate(true),
        "permanent_sites": game.permanent_sites.duplicate(true),
        "jobs": game.jobs.duplicate(true),
        "scroll_depth": float(_world.get("scroll_depth")),
        "zoom": float(_world.get("zoom")),
        "animation_phase": float(_world.get("animation_phase")),
        "viewport_size": viewport_size,
    })

func set_scene_state(state: Dictionary) -> void:
    super.set_scene_state(state)
    _update_v07_metrics()
    queue_redraw()

func visual_metrics() -> Dictionary:
    var result := metrics()
    result.merge(_v07_metrics, true)
    return result

func _update_v07_metrics() -> void:
    var depth := int(_state.get("depth", 0))
    var center_level := int(_state.get("center_level", 1))
    var viewport_size: Vector2 = _state.get("viewport_size", size)
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        viewport_size = Vector2(1280.0, 800.0)

    var profile: Dictionary = Layout.surface_profile(center_level)
    var modules: Array = profile.get("modules", [])
    var surface_asset_count := 0
    for module_id in ["workshop", "silo", "ventilation", "crane"]:
        if modules.has(module_id):
            surface_asset_count += 1

    var station_count := 0
    for station_depth in STATION_DEPTHS:
        if station_depth <= depth:
            station_count += 1

    var resource_count := 3 + (1 if depth >= 90 else 0)
    var all_assets_available := true
    for asset_id in [
        "surface_workshop", "surface_silo", "surface_ventilation", "surface_crane",
        "shaft_station", "shaft_elevator", "iron_installation", "coal_installation",
        "copper_installation", "crystal_installation",
    ]:
        if not V07Assets.has_asset(asset_id):
            all_assets_available = false
            break

    var surface_rects := _surface_v07_rects(viewport_size.x, _depth_to_y(0.0), modules, viewport_size.x < 800.0)
    var surface_bounds_ok := true
    var aspect_ok := all_assets_available
    for asset_id_value in surface_rects:
        var asset_id := str(asset_id_value)
        var texture := V07Assets.texture_for(asset_id)
        var target: Rect2 = surface_rects[asset_id_value]
        if texture == null:
            aspect_ok = false
            surface_bounds_ok = false
            continue
        var fitted := _fit_rect(texture.get_size(), target)
        if not _rect_inside_viewport(fitted, viewport_size):
            surface_bounds_ok = false
        if fitted.size.y <= 0.0 or absf((fitted.size.x / fitted.size.y) - (texture.get_size().x / texture.get_size().y)) > 0.001:
            aspect_ok = false

    var shaft_rect := _shaft_v07_rect(viewport_size, depth)
    var elevator_rect := _elevator_v07_rect(shaft_rect, depth)
    var elevator_inside := elevator_rect.size.x > 0.0 and elevator_rect.position.x >= shaft_rect.position.x and elevator_rect.end.x <= shaft_rect.end.x

    _v07_metrics = {
        "v07_major_asset_count": surface_asset_count + station_count + 1 + resource_count,
        "v07_station_count": station_count,
        "v07_elevator_inside_shaft": elevator_inside,
        "v07_resource_identity_ok": resource_count >= 3 and all_assets_available,
        "v07_surface_assets_in_bounds": surface_bounds_ok,
        "v07_asset_aspect_ok": aspect_ok,
        "v07_crystal_visible": depth >= 90,
        "v07_resource_installation_count": resource_count,
        "v07_surface_asset_count": surface_asset_count,
        "v07_surface_uses_assets": surface_asset_count > 0 and all_assets_available,
        "v07_shaft_uses_assets": station_count > 0 and V07Assets.has_asset("shaft_station") and V07Assets.has_asset("shaft_elevator"),
        "v07_elevator_rect": elevator_rect,
        "v07_shaft_rect": shaft_rect,
    }

func _fit_rect(source_size: Vector2, target: Rect2) -> Rect2:
    if source_size.x <= 0.0 or source_size.y <= 0.0:
        return target
    var scale_factor := minf(target.size.x / source_size.x, target.size.y / source_size.y)
    var fitted_size := source_size * scale_factor
    return Rect2(target.position + (target.size - fitted_size) * 0.5, fitted_size)

func _draw_v07_asset(id: String, target: Rect2) -> Rect2:
    var texture := V07Assets.texture_for(id)
    if texture == null:
        return Rect2()
    var actual := _fit_rect(texture.get_size(), target)
    draw_texture_rect(texture, actual, false)
    return actual

func _rect_inside_viewport(rect: Rect2, viewport_size: Vector2) -> bool:
    return rect.position.x >= -0.5 and rect.position.y >= -0.5 and rect.end.x <= viewport_size.x + 0.5 and rect.end.y <= viewport_size.y + 0.5

func _surface_v07_rects(viewport_width: float, ground_y: float, modules: Array, narrow: bool) -> Dictionary:
    var rects: Dictionary = {}
    if ground_y < -140.0:
        return rects
    if narrow:
        if modules.has("workshop"):
            rects["surface_workshop"] = Rect2(8.0, maxf(0.0, ground_y - 70.0), 150.0, 108.0)
        if modules.has("silo"):
            rects["surface_silo"] = Rect2(162.0, maxf(0.0, ground_y - 66.0), 112.0, 102.0)
        if modules.has("ventilation"):
            rects["surface_ventilation"] = Rect2(viewport_width - 160.0, maxf(0.0, ground_y - 64.0), 150.0, 104.0)
    else:
        if modules.has("workshop"):
            rects["surface_workshop"] = Rect2(18.0, maxf(0.0, ground_y - 72.0), 235.0, 158.0)
        if modules.has("silo"):
            rects["surface_silo"] = Rect2(260.0, maxf(0.0, ground_y - 68.0), 170.0, 138.0)
        if modules.has("ventilation"):
            rects["surface_ventilation"] = Rect2(viewport_width - 430.0, maxf(0.0, ground_y - 68.0), 175.0, 132.0)
        if modules.has("crane"):
            rects["surface_crane"] = Rect2(viewport_width - 250.0, maxf(0.0, ground_y - 74.0), 232.0, 162.0)
    return rects

func _draw_surface_base() -> void:
    var ground_y := _depth_to_y(0.0)
    if ground_y < -140.0 or ground_y > size.y + 140.0:
        return

    var center_level := int(_state.get("center_level", 1))
    var profile: Dictionary = Layout.surface_profile(center_level)
    var modules: Array = profile.get("modules", [])
    var narrow := size.x < 800.0
    var shaft_x := size.x * 0.5

    draw_rect(Rect2(0.0, maxf(0.0, ground_y - 92.0), size.x, 170.0), Color("0d171d"))
    draw_rect(Rect2(0.0, ground_y - 10.0, size.x, 18.0), Color("282c2d"))
    draw_line(Vector2(0.0, ground_y), Vector2(size.x, ground_y), Color("a16c3f"), 4.0)

    var rects := _surface_v07_rects(size.x, ground_y, modules, narrow)
    for asset_id_value in rects:
        _draw_v07_asset(str(asset_id_value), rects[asset_id_value])

    if modules.has("headframe"):
        _draw_headframe(shaft_x, ground_y)
    if modules.has("pipe_network"):
        _draw_surface_utilities(ground_y, shaft_x)
    if modules.has("antenna") and not narrow:
        _draw_antenna(size.x * 0.74, ground_y)
    _draw_surface_lights(ground_y, mini(int(profile.get("light_count", 4)), 6 if not narrow else 4))

func _shaft_v07_rect(viewport_size: Vector2, depth: int) -> Rect2:
    if depth <= 0:
        return Rect2()
    var profile: Dictionary = Layout.shaft_profile(viewport_size.x, depth)
    var shaft_width := float(profile.get("width", 120.0))
    var top_y := _depth_to_y(0.0)
    var bottom_y := _depth_to_y(float(depth) + 10.0)
    var top := minf(top_y, bottom_y)
    var bottom := maxf(top_y, bottom_y)
    return Rect2(viewport_size.x * 0.5 - shaft_width * 0.5, top, shaft_width, maxf(1.0, bottom - top))

func _elevator_v07_rect(shaft_rect: Rect2, depth: int) -> Rect2:
    if depth <= 0 or shaft_rect.size.x <= 0.0:
        return Rect2()
    var travel_top := shaft_rect.position.y + 46.0
    var travel_bottom := maxf(travel_top, shaft_rect.end.y - 60.0)
    var t := fposmod(float(_state.get("animation_phase", 0.0)) * 0.07, 1.0)
    var y := lerpf(travel_top, travel_bottom, t)
    var target_width := minf(88.0 if size.x >= 800.0 else 66.0, shaft_rect.size.x - 24.0)
    var target := Rect2(shaft_rect.get_center().x - target_width * 0.5, y - 64.0, target_width, 128.0)
    var texture := V07Assets.texture_for("shaft_elevator")
    if texture == null:
        return target
    return _fit_rect(texture.get_size(), target)

func _draw_shaft_stations(center_x: float, shaft_width: float, profile: Dictionary) -> void:
    var station_depths: Array = profile.get("station_depths", [])
    var target_width := 380.0 if size.x >= 800.0 else 270.0
    var target_height := 216.0 if size.x >= 800.0 else 154.0
    for station_depth in station_depths:
        var y := _depth_to_y(float(station_depth))
        if y < -180.0 or y > size.y + 180.0:
            continue
        var station_target := Rect2(center_x - target_width * 0.5, y - target_height * 0.5, target_width, target_height)
        draw_circle(Vector2(center_x, y), target_width * 0.30, Color(0.95, 0.58, 0.25, 0.025))
        var actual := _draw_v07_asset("shaft_station", station_target)
        if actual.size.x > 0.0:
            draw_line(Vector2(actual.position.x + 12.0, y + actual.size.y * 0.38), Vector2(actual.end.x - 12.0, y + actual.size.y * 0.38), Color(0.72, 0.48, 0.29, 0.52), 3.0)

func _draw_elevator(center_x: float, half_width: float, top: float, bottom: float) -> void:
    if not bool(_metrics.get("elevator_visible", false)):
        return
    var shaft_rect := Rect2(center_x - half_width, top, half_width * 2.0, maxf(1.0, bottom - top))
    var actual := _elevator_v07_rect(shaft_rect, int(_state.get("depth", 0)))
    if actual.size.x <= 0.0:
        return
    draw_circle(actual.get_center(), actual.size.x * 0.80, Color(0.95, 0.58, 0.25, 0.045))
    _draw_v07_asset("shaft_elevator", actual)
    var counter_x := center_x + half_width - 18.0
    var counter_y := shaft_rect.end.y - (actual.get_center().y - shaft_rect.position.y)
    draw_rect(Rect2(counter_x - 5.0, counter_y - 18.0, 10.0, 36.0), Color("725a48"))

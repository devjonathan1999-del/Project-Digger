class_name MineAssetRenderer
extends "res://src/industry/ui/mine_final_module_renderer.gd"

const V07Assets = preload("res://src/industry/ui/mine_v07_assets.gd")
const PortraitPainter = preload("res://src/industry/ui/mine_portrait_painter.gd")
const FinalAssets = preload("res://src/industry/ui/mine_final_assets.gd")
const STATION_DEPTHS: Array[int] = [30, 60, 90, 120, 150]
const SHALLOW_RESOURCE_ASSETS: Array[String] = ["iron_installation", "coal_installation", "copper_installation"]
const NARROW_RESOURCE_SAFE_TOP := 26.0

var _session
var _world: Control
var _v07_metrics: Dictionary = {}

func next_progression_caption(depth: int) -> String:
    return PortraitPainter.next_progression_caption(depth)

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
    var mine_rates: Dictionary = {}
    if game.has_method("mine_rate"):
        for id in ["iron", "coal", "copper"]:
            mine_rates[id] = game.mine_rate(id)
    var viewport_size := size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        viewport_size = _world.size
    set_scene_state({
        "depth": game.depth,
        "center_level": game.center_level,
        "mine_levels": game.mine_levels.duplicate(true),
        "mine_rates": mine_rates,
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

func _depth_to_y(depth_value: float) -> float:
    var viewport_size: Vector2 = _state.get("viewport_size", size)
    var origin := 200.0 if viewport_size.x < 800.0 else 72.0
    return origin + (depth_value - float(_state.get("scroll_depth", 0.0))) * PIXELS_PER_METER * maxf(0.01, float(_state.get("zoom", 1.0)))

func _draw() -> void:
    if size.x < 800.0:
        var draw_state := _state.duplicate()
        draw_state["portrait_crystal"] = final_crystal_binding()
        PortraitPainter.draw_scene(self, draw_state, _resource_v07_rects(size, int(_state.get("depth", 0)), true))
        return
    super._draw()
    if size.x < 800.0:
        _draw_portrait_depth_markers()
        _draw_portrait_front()

func uses_final_portrait() -> bool:
    return size.x < 800.0

func final_drill_rect() -> Rect2:
    var width := clampf(size.x * 0.06, 24.0, 42.0) * 1.6
    var texture := FinalAssets.texture_for("drill")
    var height := width * texture.get_height() / float(texture.get_width()) if texture != null else 128.0
    return Rect2(size.x * 0.5 - width * 0.5, _depth_to_y(float(_state.get("depth", 0)) + 10.0) - height, width, height)

func final_crystal_binding() -> Dictionary:
    var sites = _state.get("permanent_sites", {})
    var result: Dictionary = {}
    if sites is Dictionary:
        for id in sites:
            var site: Dictionary = sites[id]
            if str(site.get("type", "")) != "crystal_cavern":
                continue
            if not result.is_empty() and int(result["depth"]) <= int(site.get("depth", 0)):
                continue
            result = {"id": str(id), "kind": "site", "depth": int(site.get("depth", 0)), "active": bool(site.get("active", false)), "rate": float(site.get("rate", 0.0)), "state": "opened"}
    if not result.is_empty():
        return result
    var discoveries = _state.get("discoveries", {})
    if discoveries is Dictionary:
        for id in discoveries:
            var discovery: Dictionary = discoveries[id]
            if str(discovery.get("type", "")) != "crystal_cavern":
                continue
            if not result.is_empty() and int(result["depth"]) <= int(discovery.get("depth", 0)):
                continue
            result = {"id": str(id), "kind": "discovery", "depth": int(discovery.get("depth", 0)), "active": false, "rate": 0.0, "state": str(discovery.get("state", "detected"))}
    return result

func _draw_final_geology() -> void:
    super._draw_final_geology()
    if size.x >= 800.0:
        return
    var front_y := _depth_to_y(float(_state.get("depth", 0)) + 10.0)
    var future_top := clampf(front_y, 0.0, size.y)
    draw_rect(Rect2(0.0, future_top, size.x, size.y - future_top), Color(0.015, 0.025, 0.03, 0.32))
    # A subdued survey line gives the unexplored rock a direction without
    # suggesting that the shaft has already been excavated.
    var survey_y := maxf(0.0, front_y + 56.0)
    while survey_y < size.y:
        draw_line(Vector2(size.x * 0.5, survey_y), Vector2(size.x * 0.5, survey_y + 8.0), Color(0.44, 0.52, 0.54, 0.20), 1.0)
        survey_y += 24.0

func _draw_rock_strata(geology: Dictionary, rock_top: float, cyan_strength: float) -> void:
    var filled_geology := geology.duplicate()
    if size.x < 800.0:
        # The former fixed count left the bottom half of a tall portrait
        # viewport without strata, especially at shallow depths.
        filled_geology["strata_count"] = maxi(int(geology.get("strata_count", 3)), ceili((size.y - rock_top) / 78.0))
    super._draw_rock_strata(filled_geology, rock_top, cyan_strength)

func _draw_gallery_network(depth: int, cyan_strength: float) -> void:
    if size.x >= 800.0:
        super._draw_gallery_network(depth, cyan_strength)
        return
    for horizon in STATION_DEPTHS:
        if horizon > depth:
            continue
        var y := _depth_to_y(float(horizon))
        if y >= -100.0 and y <= size.y + 100.0:
            _draw_gallery_cavity(float(horizon), 1 if horizon % 60 == 30 else -1, y, cyan_strength * 0.35)

func _draw_large_cavities(depth: int, cyan_strength: float) -> void:
    if size.x >= 800.0:
        super._draw_large_cavities(depth, cyan_strength)
        return
    # The illustrated crystal cavity owns its silhouette; avoid duplicating
    # it with large procedural halos under neighboring installations.
    for horizon in [90, 120, 150]:
        if horizon > depth:
            continue
        var y := _depth_to_y(float(horizon) + 12.0)
        var x := size.x * (0.20 if horizon % 60 == 30 else 0.80)
        if y < -30.0 or y > size.y + 30.0:
            continue
        draw_line(Vector2(x - 24.0, y + 4.0), Vector2(x + 18.0, y - 6.0), Color(0.16, 0.45 + cyan_strength * 0.1, 0.46, 0.26), 3.0)

func _draw_rock_relief_mass(x_start: float, x_end: float, y: float, relief_depth: float, index: int, side: int) -> void:
    if size.x >= 800.0:
        super._draw_rock_relief_mass(x_start, x_end, y, relief_depth, index, side)
        return
    var width := minf(92.0, x_end - x_start)
    var x := x_start if side < 0 else x_end - width
    var ridge := PackedVector2Array([
        Vector2(x, y + 12.0), Vector2(x + width * 0.20, y - 6.0),
        Vector2(x + width * 0.55, y - 13.0 - float(index % 3) * 3.0),
        Vector2(x + width, y + 4.0), Vector2(x + width * 0.70, y + 20.0),
        Vector2(x + width * 0.25, y + 26.0),
    ])
    draw_colored_polygon(ridge, Color(0.05, 0.08, 0.09, 0.55))
    draw_polyline(PackedVector2Array([ridge[0], ridge[1], ridge[2], ridge[3]]), Color(0.29, 0.35, 0.35, 0.22), 2.0, true)

func _draw_ambient_effects(depth: int, cyan_strength: float) -> void:
    if size.x >= 800.0:
        super._draw_ambient_effects(depth, cyan_strength)
        return
    var phase := float(_state.get("animation_phase", 0.0))
    for index in range(18):
        var x := fposmod(31.0 + float(index) * 97.0 + phase * 3.0, maxf(1.0, size.x - 24.0)) + 12.0
        var y := fposmod(53.0 + float(index) * 71.0 + phase * 5.0, maxf(1.0, size.y - 30.0)) + 15.0
        draw_circle(Vector2(x, y), 1.1, Color(0.76, 0.68, 0.56, 0.10))

func _draw_portrait_depth_markers() -> void:
    var depth := int(_state.get("depth", 0))
    var shaft_width := float(Layout.shaft_profile(size.x, depth)["width"])
    var shaft_left := size.x * 0.5 - shaft_width * 0.5
    var shaft_right := size.x * 0.5 + shaft_width * 0.5
    var first := maxi(30, floori(float(_state.get("scroll_depth", 0.0)) / 30.0) * 30)
    var last := ceili(float(_state.get("scroll_depth", 0.0)) + size.y / (PIXELS_PER_METER * maxf(0.01, float(_state.get("zoom", 1.0)))))
    for horizon in range(first, last + 1, 30):
        var y := _depth_to_y(float(horizon))
        if y < 16.0 or y > size.y - 16.0:
            continue
        var on_right := horizon % 60 == 0
        var x := shaft_right + 8.0 if on_right else shaft_left - 72.0
        var plate := Rect2(x, y - 12.0, 64.0, 24.0)
        draw_rect(plate, Color("0b161d"))
        draw_line(Vector2(x, plate.end.y), Vector2(plate.end.x, plate.end.y), Color("89613e") if horizon <= depth else Color("36474f"), 1.0)
        draw_string(ThemeDB.fallback_font, Vector2(x + 4.0, y + 5.0), "−%d m" % horizon, HORIZONTAL_ALIGNMENT_CENTER, 56.0, 14, Color("e6c3a1") if horizon <= depth else Color("8297a4"))

func _draw_portrait_front() -> void:
    var depth := int(_state.get("depth", 0))
    var front_y := _depth_to_y(float(depth) + 10.0)
    if front_y < 32.0 or front_y > size.y - 80.0:
        return
    var center_x := size.x * 0.5
    var half := float(Layout.shaft_profile(size.x, depth)["width"]) * 0.5
    var active := (_state.get("jobs", {}) as Dictionary).has("drill")
    var metal := Color("72848d")
    draw_rect(Rect2(center_x - 23.0, front_y - 48.0, 46.0, 24.0), Color("303e45"))
    draw_rect(Rect2(center_x - 18.0, front_y - 44.0, 36.0, 5.0), Color("e5a45e") if active else Color("a77c4e"))
    for x in [-14.0, -7.0, 0.0, 7.0, 14.0]:
        draw_line(Vector2(center_x + float(x), front_y - 35.0), Vector2(center_x + float(x), front_y - 25.0), metal, 2.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(center_x - 16.0, front_y - 23.0), Vector2(center_x + 16.0, front_y - 23.0),
        Vector2(center_x, front_y - 4.0),
    ]), metal)
    draw_line(Vector2(center_x - half, front_y), Vector2(center_x + half, front_y), Color("d59758"), 4.0)
    for x in range(int(center_x - half + 6.0), int(center_x + half - 10.0), 16):
        draw_line(Vector2(float(x), front_y + 3.0), Vector2(float(x) + 8.0, front_y + 11.0), Color("73583c"), 3.0)
    var caption := next_progression_caption(depth)
    var width := minf(132.0, size.x * 0.28)
    var plate := Rect2(center_x - width * 0.5, front_y + 18.0, width, 30.0)
    draw_rect(plate, Color("0d1b23"))
    draw_string(ThemeDB.fallback_font, Vector2(plate.position.x + 4.0, plate.position.y + 20.0), caption, HORIZONTAL_ALIGNMENT_CENTER, width - 8.0, 14, Color("9eb3c5"))

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

    var resource_ids := _resource_asset_ids(depth)
    var resource_targets := _resource_v07_rects(viewport_size, depth, viewport_size.x < 800.0)
    var resource_rects: Dictionary = {}
    var resources_use_assets := true
    for resource_id_value in resource_ids:
        var resource_id := str(resource_id_value)
        var texture := V07Assets.texture_for(resource_id)
        if texture == null or not resource_targets.has(resource_id):
            resources_use_assets = false
            continue
        resource_rects[resource_id] = _fit_rect(texture.get_size(), resource_targets[resource_id])

    _v07_metrics = {
        "v07_major_asset_count": surface_asset_count + station_count + 1 + resource_ids.size(),
        "v07_station_count": station_count,
        "v07_elevator_inside_shaft": elevator_inside,
        "v07_resource_identity_ok": resource_ids.size() >= 3 and resources_use_assets,
        "v07_surface_assets_in_bounds": surface_bounds_ok,
        "v07_asset_aspect_ok": aspect_ok,
        "v07_crystal_visible": depth >= 90,
        "v07_resource_installation_count": resource_ids.size(),
        "v07_surface_asset_count": surface_asset_count,
        "v07_surface_uses_assets": surface_asset_count > 0 and all_assets_available,
        "v07_shaft_uses_assets": station_count > 0 and V07Assets.has_asset("shaft_station") and V07Assets.has_asset("shaft_elevator"),
        "v07_elevator_rect": elevator_rect,
        "v07_shaft_rect": shaft_rect,
        "v07_resource_asset_ids": resource_ids,
        "v07_resource_asset_count": resource_ids.size(),
        "v07_crystal_asset_drawn": depth >= 90,
        "v07_resources_use_assets": resources_use_assets,
        "v07_resource_rects": resource_rects,
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
        var shaft_width := float(Layout.shaft_profile(viewport_width, 150)["width"])
        var lane_width := (viewport_width - shaft_width) * 0.5 - 28.0
        var left_main_width := lane_width * 0.59
        var second_width := lane_width - left_main_width - 8.0
        if modules.has("workshop"):
            rects["surface_workshop"] = Rect2(10.0, ground_y - 82.0, left_main_width, 112.0)
        if modules.has("silo"):
            rects["surface_silo"] = Rect2(18.0 + left_main_width, ground_y - 82.0, second_width, 112.0)
        if modules.has("ventilation"):
            rects["surface_ventilation"] = Rect2(viewport_width - 10.0 - lane_width, ground_y - 82.0, left_main_width if modules.has("crane") else lane_width, 112.0)
        if modules.has("crane"):
            rects["surface_crane"] = Rect2(viewport_width - 10.0 - second_width, ground_y - 82.0, second_width, 112.0)
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

func _resource_asset_ids(depth: int) -> Array:
    var ids: Array = SHALLOW_RESOURCE_ASSETS.duplicate()
    if depth >= 90:
        ids.append("crystal_installation")
    return ids

func _resource_v07_rects(viewport_size: Vector2, depth: int, narrow: bool) -> Dictionary:
    var shallow_y := _depth_to_y(12.0)
    var rects: Dictionary = {}
    if narrow:
        var shaft_width := float(Layout.shaft_profile(viewport_size.x, depth)["width"])
        var lane_width := (viewport_size.x - shaft_width) * 0.5 - 24.0
        var crystal_width := lane_width
        var chamber_height := lane_width * 0.62
        var iron_y := _depth_to_y(22.0)
        var coal_y := _depth_to_y(50.0)
        var copper_y := _depth_to_y(78.0)
        rects["iron_installation"] = Rect2(10.0, iron_y - chamber_height * 0.5, lane_width, chamber_height)
        rects["coal_installation"] = Rect2(viewport_size.x - 10.0 - lane_width, coal_y - chamber_height * 0.5, lane_width, chamber_height)
        rects["copper_installation"] = Rect2(10.0, copper_y - chamber_height * 0.5, lane_width, chamber_height)
        if depth >= 90:
            var crystal_binding := final_crystal_binding()
            var crystal_y_narrow := _depth_to_y(float(crystal_binding.get("depth", 108.0)))
            rects["crystal_installation"] = Rect2(viewport_size.x - 10.0 - crystal_width, crystal_y_narrow - chamber_height * 0.5, crystal_width, chamber_height)
    else:
        rects["iron_installation"] = Rect2(12.0, shallow_y - 82.0, 305.0, 162.0)
        rects["coal_installation"] = Rect2(308.0, shallow_y - 76.0, 260.0, 150.0)
        rects["copper_installation"] = Rect2(viewport_size.x - 340.0, shallow_y - 84.0, 320.0, 166.0)
        if depth >= 90:
            var crystal_y := _depth_to_y(90.0)
            rects["crystal_installation"] = Rect2(viewport_size.x * 0.77 - 210.0, crystal_y - 105.0, 420.0, 210.0)
    return rects

func _shallow_resource_visible(target: Rect2, narrow: bool) -> bool:
    if target.end.y < -170.0 or target.position.y > size.y + 170.0:
        return false
    if narrow and target.position.y < NARROW_RESOURCE_SAFE_TOP:
        return false
    return true

func _draw_resource_installations() -> void:
    var depth := int(_state.get("depth", 0))
    var viewport_size: Vector2 = _state.get("viewport_size", size)
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        viewport_size = size
    var narrow := size.x < 800.0
    var rects := _resource_v07_rects(viewport_size, depth, narrow)

    for asset_id in SHALLOW_RESOURCE_ASSETS:
        if not rects.has(asset_id):
            continue
        var target: Rect2 = rects[asset_id]
        if not _shallow_resource_visible(target, narrow):
            continue
        _draw_resource_cavity(target, asset_id)
        if narrow:
            var install_depth: int = {"iron_installation": 22, "coal_installation": 50, "copper_installation": 78}[asset_id]
            if install_depth <= depth:
                var shaft_half := float(Layout.shaft_profile(size.x, depth)["width"]) * 0.5
                var on_right := asset_id == "coal_installation"
                var shaft_edge := size.x * 0.5 + shaft_half if on_right else size.x * 0.5 - shaft_half
                var bay_edge := target.position.x if on_right else target.end.x
                draw_line(Vector2(shaft_edge, target.get_center().y + 20.0), Vector2(bay_edge, target.get_center().y + 20.0), Color("4b595c"), 4.0)
        var actual := _draw_v07_asset(asset_id, target)
        _draw_resource_foreground(actual, asset_id)

    if depth >= 90 and rects.has("crystal_installation"):
        var crystal_target: Rect2 = rects["crystal_installation"]
        if crystal_target.end.y >= -180.0 and crystal_target.position.y <= size.y + 180.0:
            var center := crystal_target.get_center()
            draw_circle(center, minf(crystal_target.size.x, crystal_target.size.y) * 0.62, Color(0.13, 0.78, 0.82, 0.055))
            draw_circle(center, minf(crystal_target.size.x, crystal_target.size.y) * 0.38, Color(0.16, 0.88, 0.90, 0.045))
            _draw_resource_cavity(crystal_target, "crystal_installation")
            var actual_crystal := _draw_v07_asset("crystal_installation", crystal_target)
            _draw_resource_foreground(actual_crystal, "crystal_installation")
            if narrow:
                draw_string(ThemeDB.fallback_font, Vector2(crystal_target.position.x, crystal_target.position.y - 8.0), "Cristal", HORIZONTAL_ALIGNMENT_CENTER, crystal_target.size.x, 16, Color("44d9d2"))

func _resource_cavity_polygon(target: Rect2) -> PackedVector2Array:
    var pad_x := target.size.x * 0.07
    var pad_y := target.size.y * 0.14
    var cavity := Rect2(target.position - Vector2(pad_x, pad_y), target.size + Vector2(pad_x * 2.0, pad_y * 2.0))
    var w := cavity.size.x
    var h := cavity.size.y
    var x := cavity.position.x
    var y := cavity.position.y
    return PackedVector2Array([
        Vector2(x + w * 0.05, y + h * 0.16),
        Vector2(x + w * 0.20, y + h * 0.02),
        Vector2(x + w * 0.46, y + h * 0.07),
        Vector2(x + w * 0.76, y),
        Vector2(x + w * 0.96, y + h * 0.17),
        Vector2(x + w, y + h * 0.47),
        Vector2(x + w * 0.97, y + h * 0.80),
        Vector2(x + w * 0.80, y + h),
        Vector2(x + w * 0.54, y + h * 0.95),
        Vector2(x + w * 0.27, y + h),
        Vector2(x + w * 0.04, y + h * 0.82),
        Vector2(x, y + h * 0.55),
    ])

func _draw_resource_cavity(target: Rect2, asset_id: String) -> void:
    var cavity := _resource_cavity_polygon(target)
    var cavity_color := Color(0.025, 0.045, 0.052, 0.88)
    if asset_id == "coal_installation":
        cavity_color = Color(0.022, 0.028, 0.030, 0.90)
    elif asset_id == "copper_installation":
        cavity_color = Color(0.045, 0.055, 0.050, 0.88)
    elif asset_id == "crystal_installation":
        cavity_color = Color(0.025, 0.060, 0.070, 0.90)
    draw_colored_polygon(cavity, cavity_color)
    var outline := cavity.duplicate()
    outline.append(cavity[0])
    draw_polyline(outline, Color(0.28, 0.30, 0.28, 0.34), 4.0, true)

func _draw_resource_foreground(actual: Rect2, asset_id: String) -> void:
    if actual.size.x <= 0.0:
        return
    var rock := Color(0.055, 0.075, 0.078, 0.96)
    if asset_id == "crystal_installation":
        rock = Color(0.035, 0.080, 0.086, 0.94)
    var radius := maxf(13.0, actual.size.y * 0.13)
    draw_circle(Vector2(actual.position.x + radius * 0.55, actual.end.y - radius * 0.25), radius, rock)
    draw_circle(Vector2(actual.end.x - radius * 0.45, actual.end.y - radius * 0.20), radius * 0.85, rock)
    draw_line(Vector2(actual.position.x + actual.size.x * 0.10, actual.end.y - 3.0), Vector2(actual.end.x - actual.size.x * 0.08, actual.end.y - 5.0), Color(0.31, 0.29, 0.25, 0.45), 4.0)

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
    if size.x < 800.0:
        target_width = minf(180.0, (size.x - shaft_width) * 0.5 - 28.0)
        target_height = 102.0
    for station_depth in station_depths:
        var y := _depth_to_y(float(station_depth))
        if y < -180.0 or y > size.y + 180.0:
            continue
        var station_target := Rect2(center_x - target_width * 0.5, y - target_height * 0.5, target_width, target_height)
        if size.x < 800.0:
            # A station serves the shaft from a side bay; its machinery must not cover the rails.
            var on_right := int(station_depth) % 60 == 30
            station_target.position.x = center_x + shaft_width * 0.5 + 18.0 if on_right else center_x - shaft_width * 0.5 - 18.0 - target_width
            var connection_x := station_target.position.x if on_right else station_target.end.x
            var shaft_edge := center_x + shaft_width * 0.5 if on_right else center_x - shaft_width * 0.5
            draw_line(Vector2(shaft_edge, y), Vector2(connection_x, y), Color("72848d"), 4.0)
        draw_circle(station_target.get_center(), target_width * 0.30, Color(0.95, 0.58, 0.25, 0.025))
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

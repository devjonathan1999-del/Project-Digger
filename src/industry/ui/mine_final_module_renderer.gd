class_name MineFinalModuleRenderer
extends "res://src/industry/ui/mine_module_renderer.gd"

func set_scene_state(state: Dictionary) -> void:
    super.set_scene_state(state)
    var viewport_size: Vector2 = state.get("viewport_size", size)
    if viewport_size.x <= 0.0:
        viewport_size = Vector2(1280.0, 800.0)
    var narrow := viewport_size.x < 800.0
    var center_level := int(state.get("center_level", 1))
    var surface_profile: Dictionary = Layout.surface_profile(center_level)
    var modules: Array = surface_profile.get("modules", [])
    var rects := _surface_asset_rects(viewport_size.x, 0.0, modules, narrow)
    _metrics["narrow_mode"] = narrow
    _metrics["shaft_center_x"] = viewport_size.x * 0.5
    _metrics["surface_bounds_ok"] = _rects_within_width(rects, viewport_size.x)
    _metrics["decorative_detail_level"] = 1 if narrow else 2
    queue_redraw()

func _draw_surface_base() -> void:
    var ground_y := _depth_to_y(0.0)
    if ground_y < -140.0 or ground_y > size.y + 140.0:
        return

    var center_level := int(_state.get("center_level", 1))
    var profile: Dictionary = Layout.surface_profile(center_level)
    var modules: Array = profile.get("modules", [])
    var narrow := size.x < 800.0
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
